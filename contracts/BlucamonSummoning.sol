// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract BlucamonSummoning {
    address blucamonOwnershipContract;
    address payable founder;

    event SetSummonFee(uint256 _newSummonFee);
    event SetSetter(address _newSetter);
    event Transfer(uint256 _value);

    constructor(address _ownershipContractAddress, address _founderAddress) {
        blucamonOwnershipContract = _ownershipContractAddress;
        founder = payable(_founderAddress);
        setter = msg.sender;
    }

    uint256 public summonFee = 0.001 ether;
    address setter;

    modifier onlyFounder() {
        require(msg.sender == founder, "S_SMN_200");
        _;
    }

    modifier onlySetter() {
        require(msg.sender == setter, "S_SMN_201");
        _;
    }

    function setSetter(address _newSetter) external onlySetter {
        setter = _newSetter;
        emit SetSetter(_newSetter);
    }

    function setSummonFee(uint256 _newSummonFee) external onlySetter {
        summonFee = _newSummonFee;
        emit SetSummonFee(_newSummonFee);
    }

    function summon(uint256 _id) external payable {
        (, bytes memory ownerData) = blucamonOwnershipContract.call(
            abi.encodeWithSignature("getBlucamonOwner(uint256)", _id)
        );
        address owner = abi.decode(ownerData, (address));
        require(owner == msg.sender, "S_ONS_100");
        require(msg.value == summonFee, "S_SMN_101");
        (bool result, ) = blucamonOwnershipContract.call(
            abi.encodeWithSignature("summon(uint256)", _id)
        );
        require(result, "S_SMN_100");
    }

    function transfer(uint256 _value) external payable onlyFounder {
        founder.transfer(_value);
        emit Transfer(_value);
    }
}
