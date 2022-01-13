// SPDX-License-Identifier: MIT

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Timelock {
    using SafeMath for uint256;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 1 seconds;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    address public summoningContractAddress;
    address public ownershipContractAddress;
    address public exclusiveSaleContractAddress;
    address public standardSaleContractAddress;
    uint256 public delay;
    bool public admin_initialized;

    mapping(bytes32 => bool) public queuedTransactions;

    constructor(
        address admin_,
        uint256 delay_,
        address summoningContractAddress_,
        address ownershipContractAddress_,
        address exclusiveSaleContractAddress_,
        address standardSaleContractAddress_
    ) {
        require(delay_ >= MINIMUM_DELAY, "S_TLC_200");
        require(delay_ <= MAXIMUM_DELAY, "S_TLC_201");

        admin = admin_;
        delay = delay_;
        admin_initialized = false;
        summoningContractAddress = summoningContractAddress_;
        ownershipContractAddress = ownershipContractAddress_;
        exclusiveSaleContractAddress = exclusiveSaleContractAddress_;
        standardSaleContractAddress = standardSaleContractAddress_;
    }

    function setDelay(uint256 delay_) public {
        require(msg.sender == address(this), "S_TLC_101");
        require(delay_ >= MINIMUM_DELAY, "S_TLC_200");
        require(delay_ <= MAXIMUM_DELAY, "S_TLC_201");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "S_TLC_102");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        // allows one time setting of admin for deployment purposes
        if (admin_initialized) {
            require(msg.sender == address(this), "S_TLC_103");
        } else {
            require(msg.sender == admin, "S_TLC_100");
            admin_initialized = true;
        }
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        require(eta >= getBlockTimestamp().add(delay), "S_TLC_300");

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        require(queuedTransactions[txHash], "S_TLC_400");
        require(getBlockTimestamp() >= eta, "S_TLC_301");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "S_TLC_302");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(success, "S_TLC_500");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    function queueSummoningSetSetter(address _newSetter, uint256 eta)
        public
        returns (bytes32)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSetter(address)",
            _newSetter
        );
        return queueTransaction(summoningContractAddress, 0, "", payload, eta);
    }

    function queueSummoningSetSummoningFee(uint256 _newSummonFee, uint256 eta)
        public
        returns (bytes32)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSummonFee(uint256)",
            _newSummonFee
        );
        return queueTransaction(summoningContractAddress, 0, "", payload, eta);
    }

    function queueOwnershipSetWhitelistSetter(address _newSetter, uint256 eta)
        public
        returns (bytes32)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setWhitelistSetter(address)",
            _newSetter
        );
        return queueTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function queueOwnershipSetSpawner(
        address _spawner,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSpawner(address,bool)",
            _spawner,
            _isWhitelisted
        );
        return queueTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function queueOwnershipSetBreeder(
        address _breeder,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setBreeder(address,bool)",
            _breeder,
            _isWhitelisted
        );
        return queueTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function queueOwnershipSetAirdropSetter(
        address _airdropSetter,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setAirdropSetter(address,bool)",
            _airdropSetter,
            _isWhitelisted
        );
        return queueTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function queueOwnershipSetFounder(
        address _founder,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFounder(address,bool)",
            _founder,
            _isWhitelisted
        );
        return queueTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function queueOwnershipSetSummoner(
        address _summoner,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSummoner(address,bool)",
            _summoner,
            _isWhitelisted
        );
        return queueTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function queueOwnershipSetFactorySetter(
        address _factorySetter,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFactorySetter(address,bool)",
            _factorySetter,
            _isWhitelisted
        );
        return queueTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function queueOwnershipSetBlucamonId(uint256 _newBlucamonId, uint256 eta)
        public
        returns (bytes32)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setBlucamonId(uint256)",
            _newBlucamonId
        );
        return queueTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function queueOwnershipSetDefaultElementalFragments(
        uint8 _newValue,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setDefaultElementalFragments(uint8)",
            _newValue
        );
        return queueTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function queueExclusiveSaleSetSetter(address _newSetter, uint256 eta)
        public
        returns (bytes32)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSetter(address)",
            _newSetter
        );
        return
            queueTransaction(exclusiveSaleContractAddress, 0, "", payload, eta);
    }

    function queueExclusiveSaleSetFounder(address _newFounder, uint256 eta)
        public
        returns (bytes32)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFounder(address)",
            _newFounder
        );
        return
            queueTransaction(exclusiveSaleContractAddress, 0, "", payload, eta);
    }

    function queueExclusiveSaleSetDefaultRarity(
        uint8 _defaultRarity,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setDefaultRarity(uint8)",
            _defaultRarity
        );
        return
            queueTransaction(exclusiveSaleContractAddress, 0, "", payload, eta);
    }

    function queueExclusiveSaleSetEvent(
        uint8 _season,
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setEvent(uint8,uint256,uint256,uint256,uint256)",
            _season,
            _price,
            _total,
            _startTime,
            _endTime
        );
        return
            queueTransaction(exclusiveSaleContractAddress, 0, "", payload, eta);
    }

    function queueExclusiveSaleSetPrefixTokenUri(
        string memory _newPrefixTokenUri,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setPrefixTokenUri(string)",
            _newPrefixTokenUri
        );
        return
            queueTransaction(exclusiveSaleContractAddress, 0, "", payload, eta);
    }

    function queueStandardSaleSetSetter(address _newSetter, uint256 eta)
        public
        returns (bytes32)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSetter(address)",
            _newSetter
        );
        return
            queueTransaction(standardSaleContractAddress, 0, "", payload, eta);
    }

    function queueStandardSaleSetFounder(address _newFounder, uint256 eta)
        public
        returns (bytes32)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFounder(address)",
            _newFounder
        );
        return
            queueTransaction(standardSaleContractAddress, 0, "", payload, eta);
    }

    function queueStandardSaleSetEvent(
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setEvent(uint256,uint256,uint256,uint256)",
            _price,
            _total,
            _startTime,
            _endTime
        );
        return
            queueTransaction(standardSaleContractAddress, 0, "", payload, eta);
    }

    function queueStandardSaleSetPrefixTokenUri(
        string memory _newPrefixTokenUri,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setPrefixTokenUri(string)",
            _newPrefixTokenUri
        );
        return
            queueTransaction(standardSaleContractAddress, 0, "", payload, eta);
    }

    function cancelSummoningSetSetter(address _newSetter, uint256 eta) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSetter(address)",
            _newSetter
        );
        cancelTransaction(summoningContractAddress, 0, "", payload, eta);
    }

    function cancelSummoningSetSummoningFee(uint256 _newSummonFee, uint256 eta)
        public
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSummonFee(uint256)",
            _newSummonFee
        );
        cancelTransaction(summoningContractAddress, 0, "", payload, eta);
    }

    function cancelOwnershipSetWhitelistSetter(address _newSetter, uint256 eta)
        public
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setWhitelistSetter(address)",
            _newSetter
        );
        cancelTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function cancelOwnershipSetSpawner(
        address _spawner,
        bool _isWhitelisted,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSpawner(address,bool)",
            _spawner,
            _isWhitelisted
        );
        cancelTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function cancelOwnershipSetBreeder(
        address _breeder,
        bool _isWhitelisted,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setBreeder(address,bool)",
            _breeder,
            _isWhitelisted
        );
        cancelTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function cancelOwnershipSetAirdropSetter(
        address _airdropSetter,
        bool _isWhitelisted,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setAirdropSetter(address,bool)",
            _airdropSetter,
            _isWhitelisted
        );
        cancelTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function cancelOwnershipSetFounder(
        address _founder,
        bool _isWhitelisted,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFounder(address,bool)",
            _founder,
            _isWhitelisted
        );
        cancelTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function cancelOwnershipSetSummoner(
        address _summoner,
        bool _isWhitelisted,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSummoner(address,bool)",
            _summoner,
            _isWhitelisted
        );
        cancelTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function cancelOwnershipSetFactorySetter(
        address _factorySetter,
        bool _isWhitelisted,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFactorySetter(address,bool)",
            _factorySetter,
            _isWhitelisted
        );
        cancelTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function cancelOwnershipSetBlucamonId(uint256 _newBlucamonId, uint256 eta)
        public
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setBlucamonId(uint256)",
            _newBlucamonId
        );
        cancelTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function cancelOwnershipSetDefaultElementalFragments(
        uint8 _newValue,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setDefaultElementalFragments(uint8)",
            _newValue
        );
        cancelTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function cancelExclusiveSaleSetSetter(address _newSetter, uint256 eta)
        public
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSetter(address)",
            _newSetter
        );
        cancelTransaction(exclusiveSaleContractAddress, 0, "", payload, eta);
    }

    function cancelExclusiveSaleSetFounder(address _newFounder, uint256 eta)
        public
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFounder(address)",
            _newFounder
        );
        cancelTransaction(exclusiveSaleContractAddress, 0, "", payload, eta);
    }

    function cancelExclusiveSaleSetDefaultRarity(
        uint8 _defaultRarity,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setDefaultRarity(uint8)",
            _defaultRarity
        );
        cancelTransaction(exclusiveSaleContractAddress, 0, "", payload, eta);
    }

    function cancelExclusiveSaleSetEvent(
        uint8 _season,
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setEvent(uint8,uint256,uint256,uint256,uint256)",
            _season,
            _price,
            _total,
            _startTime,
            _endTime
        );
        cancelTransaction(exclusiveSaleContractAddress, 0, "", payload, eta);
    }

    function cancelExclusiveSaleSetPrefixTokenUri(
        string memory _newPrefixTokenUri,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setPrefixTokenUri(string)",
            _newPrefixTokenUri
        );
        cancelTransaction(exclusiveSaleContractAddress, 0, "", payload, eta);
    }

    function cancelStandardSaleSetSetter(address _newSetter, uint256 eta)
        public
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSetter(address)",
            _newSetter
        );
        cancelTransaction(standardSaleContractAddress, 0, "", payload, eta);
    }

    function cancelStandardSaleSetFounder(address _newFounder, uint256 eta)
        public
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFounder(address)",
            _newFounder
        );
        cancelTransaction(standardSaleContractAddress, 0, "", payload, eta);
    }

    function cancelStandardSaleSetEvent(
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setEvent(uint256,uint256,uint256,uint256)",
            _price,
            _total,
            _startTime,
            _endTime
        );
        cancelTransaction(standardSaleContractAddress, 0, "", payload, eta);
    }

    function cancelStandardSaleSetPrefixTokenUri(
        string memory _newPrefixTokenUri,
        uint256 eta
    ) public {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setPrefixTokenUri(string)",
            _newPrefixTokenUri
        );
        cancelTransaction(standardSaleContractAddress, 0, "", payload, eta);
    }

    function executeSummoningSetSetter(address _newSetter, uint256 eta)
        public
        returns (bytes memory)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSetter(address)",
            _newSetter
        );
        return
            executeTransaction(summoningContractAddress, 0, "", payload, eta);
    }

    function executeSummoningSetSummonFee(uint256 _newSummonFee, uint256 eta)
        public
        returns (bytes memory)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSummonFee(uint256)",
            _newSummonFee
        );
        return
            executeTransaction(summoningContractAddress, 0, "", payload, eta);
    }

    function executeOwnershipSetWhitelistSetter(address _newSetter, uint256 eta)
        public
        returns (bytes memory)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setWhitelistSetter(address)",
            _newSetter
        );
        return
            executeTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function executeOwnershipSetSpawner(
        address _spawner,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSpawner(address,bool)",
            _spawner,
            _isWhitelisted
        );
        return
            executeTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function executeOwnershipSetBreeder(
        address _breeder,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setBreeder(address,bool)",
            _breeder,
            _isWhitelisted
        );
        return
            executeTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function executeOwnershipSetAirdropSetter(
        address _airdropSetter,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setAirdropSetter(address,bool)",
            _airdropSetter,
            _isWhitelisted
        );
        return
            executeTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function executeOwnershipSetFounder(
        address _founder,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFounder(address,bool)",
            _founder,
            _isWhitelisted
        );
        return
            executeTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function executeOwnershipSetSummoner(
        address _summoner,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSummoner(address,bool)",
            _summoner,
            _isWhitelisted
        );
        return
            executeTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function executeOwnershipSetFactorySetter(
        address _factorySetter,
        bool _isWhitelisted,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFactorySetter(address,bool)",
            _factorySetter,
            _isWhitelisted
        );
        return
            executeTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function executeOwnershipSetBlucamonId(uint256 _newBlucamonId, uint256 eta)
        public
        returns (bytes memory)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setBlucamonId(uint256)",
            _newBlucamonId
        );
        return
            executeTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function executeOwnershipSetDefaultElementalFragments(
        uint8 _newValue,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setDefaultElementalFragments(uint8)",
            _newValue
        );
        return
            executeTransaction(ownershipContractAddress, 0, "", payload, eta);
    }

    function executeExclusiveSaleSetSetter(address _newSetter, uint256 eta)
        public
        returns (bytes memory)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSetter(address)",
            _newSetter
        );
        return
            executeTransaction(
                exclusiveSaleContractAddress,
                0,
                "",
                payload,
                eta
            );
    }

    function executeExclusiveSaleSetFounder(address _newFounder, uint256 eta)
        public
        returns (bytes memory)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFounder(address)",
            _newFounder
        );
        return
            executeTransaction(
                exclusiveSaleContractAddress,
                0,
                "",
                payload,
                eta
            );
    }

    function executeExclusiveSaleSetDefaultRarity(
        uint8 _defaultRarity,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setDefaultRarity(uint8)",
            _defaultRarity
        );
        return
            executeTransaction(
                exclusiveSaleContractAddress,
                0,
                "",
                payload,
                eta
            );
    }

    function executeExclusiveSaleSetEvent(
        uint8 _season,
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setEvent(uint8,uint256,uint256,uint256,uint256)",
            _season,
            _price,
            _total,
            _startTime,
            _endTime
        );
        return
            executeTransaction(
                exclusiveSaleContractAddress,
                0,
                "",
                payload,
                eta
            );
    }

    function executeExclusiveSaleSetPrefixTokenUri(
        string memory _newPrefixTokenUri,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setPrefixTokenUri(string)",
            _newPrefixTokenUri
        );
        return
            executeTransaction(
                exclusiveSaleContractAddress,
                0,
                "",
                payload,
                eta
            );
    }

    function executeStandardSaleSetSetter(address _newSetter, uint256 eta)
        public
        returns (bytes memory)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setSetter(address)",
            _newSetter
        );
        return
            executeTransaction(
                standardSaleContractAddress,
                0,
                "",
                payload,
                eta
            );
    }

    function executeStandardSaleSetFounder(address _newFounder, uint256 eta)
        public
        returns (bytes memory)
    {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setFounder(address)",
            _newFounder
        );
        return
            executeTransaction(
                standardSaleContractAddress,
                0,
                "",
                payload,
                eta
            );
    }

    function executeStandardSaleSetEvent(
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setEvent(uint256,uint256,uint256,uint256)",
            _price,
            _total,
            _startTime,
            _endTime
        );
        return
            executeTransaction(
                standardSaleContractAddress,
                0,
                "",
                payload,
                eta
            );
    }

    function executeStandardSaleSetPrefixTokenUri(
        string memory _newPrefixTokenUri,
        uint256 eta
    ) public returns (bytes memory) {
        require(msg.sender == admin, "S_TLC_100");
        bytes memory payload = abi.encodeWithSignature(
            "setPrefixTokenUri(string)",
            _newPrefixTokenUri
        );
        return
            executeTransaction(
                standardSaleContractAddress,
                0,
                "",
                payload,
                eta
            );
    }
}
