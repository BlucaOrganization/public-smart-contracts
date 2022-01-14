// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./libraries/SafeMath8.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ExclusiveSale {
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeMath8 for uint8;

    constructor(address _ownershipContractAddress) {
        blucamonOwnershipContract = _ownershipContractAddress;
        setter = msg.sender;
    }

    event PurchaseExclusiveEgg(uint256 blucamonId);
    event SetSetter(address _newSetter);
    event SetFounder(address _newFounder);
    event SetDefaultRarity(uint8 _defaultRarity);
    event SetEvent(
        uint8 _season,
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime
    );
    event SetPrefixTokenUri(string _newPrefixTokenUri);
    event DisableEvent();
    event Transfer(uint256 _value);

    address blucamonOwnershipContract;
    address setter;
    address payable founder;
    string prefixTokenUri;
    uint8 public defaultRarity = 100;
    uint8 public season;
    uint256 public price;
    uint256 public total;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public currentNumber = 0;

    modifier onlyFounder() {
        require(msg.sender == founder, "S_EXS_100");
        _;
    }

    modifier onlySetter() {
        require(msg.sender == setter, "S_EXS_101");
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

    function setDefaultRarity(uint8 _defaultRarity) external onlySetter {
        defaultRarity = _defaultRarity;
        emit SetDefaultRarity(_defaultRarity);
    }

    function setEvent(
        uint8 _season,
        uint256 _price,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime
    ) external onlySetter {
        require(
            block.timestamp < startTime || block.timestamp >= endTime,
            "S_EXS_502"
        );
        require(
            block.timestamp <= _startTime && _startTime < _endTime,
            "S_EXS_503"
        );
        currentNumber = 0;
        season = _season;
        price = _price;
        total = _total;
        startTime = _startTime;
        endTime = _endTime;
        emit SetEvent(_season, _price, _total, _startTime, _endTime);
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

    function transfer(uint256 _value) external onlyFounder {
        require(_value <= address(this).balance, "S_EXS_200");
        founder.transfer(_value);
        emit Transfer(_value);
    }

    function purchaseEgg() external payable {
        validatePurchasing(msg.value);
        currentNumber = currentNumber.add(1);

        uint256 newBlucamonId = getBlucamonId().add(1);
        string memory tokenUri = getTokenUri(newBlucamonId);
        uint8 rarity = getRarity();
        (bool result, ) = blucamonOwnershipContract.call(
            abi.encodeWithSignature(
                "mintBlucamon(address,string,bool,uint8,uint256,uint8)",
                msg.sender,
                tokenUri,
                false,
                rarity,
                0,
                0
            )
        );
        require(result, "S_EXS_600");
        emit PurchaseExclusiveEgg(newBlucamonId);
    }

    function getBlucamonId() private returns (uint256) {
        (, bytes memory idData) = blucamonOwnershipContract.call(
            abi.encodeWithSignature("getBlucamonId()")
        );
        return abi.decode(idData, (uint256));
    }

    function getRarity() private view returns (uint8) {
        return defaultRarity.add(season);
    }

    function getTokenUri(uint256 _id) private view returns (string memory) {
        return string(abi.encodePacked(prefixTokenUri, _id.toString()));
    }

    function validatePurchasing(uint256 _value) private view {
        require(_value == price, "S_EXS_300");
        require(currentNumber < total, "S_EXS_400");
        require(block.timestamp >= startTime, "S_EXS_500");
        require(block.timestamp < endTime, "S_EXS_501");
    }
}
