// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./BlucamonFactory.sol";

contract BlucamonAirdrop is BlucamonFactory {
    using SafeMath for uint256;

    constructor() {}

    mapping(address => AirdropEggDetail) whitelistEggDetail;
    mapping(address => bool) isClaimedMapping;

    struct AirdropEggDetail {
        uint256 id;
        string tokenUri;
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
        string[] memory _tokenUriList
    ) external onlyAirdropSetter {
        validateWhitelistParameter(_addresses, _tokenUriList);
        for (uint256 idx = 0; idx < _addresses.length; idx++) {
            whitelistEggDetail[_addresses[idx]] = setEggDetail(
                _tokenUriList[idx]
            );
        }
    }

    function setEggDetail(string memory _tokenUri)
        internal
        returns (AirdropEggDetail memory)
    {
        blucamonId = blucamonId.add(1);
        return AirdropEggDetail({id: blucamonId, tokenUri: _tokenUri});
    }

    function claim(address _address) internal {
        isClaimedMapping[_address] = true;
    }

    function validateWhitelistParameter(
        address[] memory _addresses,
        string[] memory _tokenUriList
    ) private pure {
        uint256 addressCount = _addresses.length;
        uint256 tokenUriCount = _tokenUriList.length;
        require(addressCount > 0 && tokenUriCount > 0, "S_ARD_101");
        require(addressCount == tokenUriCount, "S_ARD_102");
    }

    function getEggDetail() internal view returns (AirdropEggDetail memory) {
        return whitelistEggDetail[msg.sender];
    }
}
