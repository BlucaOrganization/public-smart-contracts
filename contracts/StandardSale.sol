// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract StandardSale {
    using Strings for uint256;
    using SafeMath for uint256;

    constructor(address _ownershipContractAddress, address _busdContractAddress)
    {
        blucamonOwnershipContract = _ownershipContractAddress;
        setter = msg.sender;
        busdContract = _busdContractAddress;
    }

    event PurchaseStandardEgg(uint256 blucamonId);
    event SetSetter(address _newSetter);
    event SetFounder(address _newFounder);
    event SetEvent(
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime
    );
    event SetPrefixTokenUri(string _newPrefixTokenUri);
    event DisableEvent();

    address blucamonOwnershipContract;
    address setter;
    address payable founder;
    string prefixTokenUri;
    uint256 public price;
    uint256 public total;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public currentNumber = 0;
    address public busdContract;

    modifier onlySetter() {
        require(msg.sender == setter, "S_STD_100");
        _;
    }

    function setSetter(address _newSetter) external onlySetter {
        setter = _newSetter;
        emit SetSetter(_newSetter);
    }

    function setFounder(address payable _newFounder) external onlySetter {
        founder = _newFounder;
        emit SetFounder(_newFounder);
    }

    function setEvent(
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime
    ) external onlySetter {
        require(
            block.timestamp < startTime || block.timestamp >= endTime,
            "S_STD_302"
        );
        require(
            block.timestamp <= _startTime && _startTime < _endTime,
            "S_STD_303"
        );
        currentNumber = 0;
        price = _price;
        total = _total;
        startTime = _startTime;
        endTime = _endTime;
        emit SetEvent(_price, _total, _startTime, _endTime);
    }

    function setPrefixTokenUri(string memory _newPrefixTokenUri)
        external
        onlySetter
    {
        prefixTokenUri = _newPrefixTokenUri;
        emit SetPrefixTokenUri(_newPrefixTokenUri);
    }

    function disableEvent() external onlySetter {
        endTime = 0;
        emit DisableEvent();
    }

    function purchaseEgg() external {
        validatePurchasing();
        (bool transferResult, ) = busdContract.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                founder,
                price
            )
        );
        require(transferResult, "S_STD_400");
        currentNumber = currentNumber.add(1);

        uint256 newBlucamonId = getBlucamonId().add(1);
        string memory tokenUri = getTokenUri(newBlucamonId);
        (bool mintResult, ) = blucamonOwnershipContract.call(
            abi.encodeWithSignature(
                "mintBlucamon(address,string,bool,uint8,uint256,uint8)",
                msg.sender,
                tokenUri,
                false,
                8,
                0,
                0
            )
        );
        require(mintResult, "S_STD_500");
        emit PurchaseStandardEgg(newBlucamonId);
    }

    function getBlucamonId() private returns (uint256) {
        (, bytes memory idData) = blucamonOwnershipContract.call(
            abi.encodeWithSignature("getBlucamonId()")
        );
        return abi.decode(idData, (uint256));
    }

    function getTokenUri(uint256 _id) private view returns (string memory) {
        return string(abi.encodePacked(prefixTokenUri, _id.toString()));
    }

    function validatePurchasing() private view {
        require(currentNumber < total, "S_STD_200");
        require(block.timestamp >= startTime, "S_STD_300");
        require(block.timestamp < endTime, "S_STD_301");
    }
}
