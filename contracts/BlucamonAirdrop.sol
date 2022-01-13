// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./BlucamonFactory.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlucamonAirdrop is BlucamonFactory {
    using Strings for uint256;
    using SafeMath for uint256;

    constructor() {}

    mapping(address => AirdropEggDetail) whitelistEggDetail;
    mapping(address => bool) isClaimedMapping;

    event SetWhitelist(
        address[] _addresses,
        string _prefixTokenUri,
        uint8[] _rarityList
    );

    struct AirdropEggDetail {
        uint256 id;
        string tokenUri;
        uint8 rarity;
    }

    modifier onlyAirdropWhitelist(address _address) {
        require(whitelistEggDetail[_address].id != 0, "S_ARD_100");
        _;
    }

    function isWhitelist() external view returns (bool) {
        return whitelistEggDetail[msg.sender].id != 0;
    }

    function isClaimed() external view returns (bool) {
        return isClaimedMapping[msg.sender];
    }

    function setWhitelist(
        address[] memory _addresses,
        string memory _prefixTokenUri,
        uint8[] memory _rarityList
    ) external onlyAirdropSetter {
        validateWhitelistParameter(_addresses, _rarityList);
        for (uint256 idx = 0; idx < _addresses.length; idx++) {
            blucamonId = blucamonId.add(1);
            whitelistEggDetail[_addresses[idx]] = setEggDetail(
                blucamonId,
                getTokenUri(_prefixTokenUri, blucamonId),
                _rarityList[idx]
            );
        }
        emit SetWhitelist(_addresses, _prefixTokenUri, _rarityList);
    }

    function setEggDetail(
        uint256 _id,
        string memory _tokenUri,
        uint8 _rarity
    ) internal pure returns (AirdropEggDetail memory) {
        return
            AirdropEggDetail({id: _id, tokenUri: _tokenUri, rarity: _rarity});
    }

    function claim(address _address) internal {
        isClaimedMapping[_address] = true;
    }

    function validateWhitelistParameter(
        address[] memory _addresses,
        uint8[] memory _rarityList
    ) private pure {
        uint256 addressCount = _addresses.length;
        uint256 rarityCount = _rarityList.length;
        require(addressCount > 0 && rarityCount > 0, "S_ARD_101");
        require(addressCount == rarityCount, "S_ARD_102");
    }

    function getEggDetail() internal view returns (AirdropEggDetail memory) {
        return whitelistEggDetail[msg.sender];
    }

    function getTokenUri(string memory _prefixTokenUri, uint256 _id)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_prefixTokenUri, _id.toString()));
    }
}
