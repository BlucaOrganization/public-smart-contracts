// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./BlucamonFactory.sol";

contract BlucamonAirdrop is BlucamonFactory {
    using SafeMath for uint256;

    constructor() {}

    mapping(address => AirdropEggDetail) whitelistEggDetail;
    mapping(address => bool) isClaimedMapping;

    event SetWhitelist(
        uint256[] _idList,
        address[] _addresses,
        string[] _tokenUriList,
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
        uint256[] memory _idList,
        address[] memory _addresses,
        string[] memory _tokenUriList,
        uint8[] memory _rarityList
    ) external onlyAirdropSetter {
        validateWhitelistParameter(
            _idList,
            _addresses,
            _tokenUriList,
            _rarityList
        );
        for (uint256 idx = 0; idx < _addresses.length; idx++) {
            whitelistEggDetail[_addresses[idx]] = setEggDetail(
                _idList[idx],
                _tokenUriList[idx],
                _rarityList[idx]
            );
        }
        emit SetWhitelist(_idList, _addresses, _tokenUriList, _rarityList);
    }

    function setEggDetail(
        uint256 _id,
        string memory _tokenUri,
        uint8 _rarity
    ) internal returns (AirdropEggDetail memory) {
        blucamonId = blucamonId.add(1);
        return
            AirdropEggDetail({id: _id, tokenUri: _tokenUri, rarity: _rarity});
    }

    function claim(address _address) internal {
        isClaimedMapping[_address] = true;
    }

    function validateWhitelistParameter(
        uint256[] memory _idList,
        address[] memory _addresses,
        string[] memory _tokenUriList,
        uint8[] memory _rarityList
    ) private pure {
        uint256 idCount = _idList.length;
        uint256 addressCount = _addresses.length;
        uint256 tokenUriCount = _tokenUriList.length;
        uint256 rarityCount = _rarityList.length;
        require(
            addressCount > 0 &&
                tokenUriCount > 0 &&
                rarityCount > 0 &&
                idCount > 0,
            "S_ARD_101"
        );
        require(
            addressCount == tokenUriCount &&
                addressCount == rarityCount &&
                addressCount == idCount,
            "S_ARD_102"
        );
    }

    function getEggDetail() internal view returns (AirdropEggDetail memory) {
        return whitelistEggDetail[msg.sender];
    }
}
