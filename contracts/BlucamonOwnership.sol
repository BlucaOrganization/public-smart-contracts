// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./BlucamonAirdrop.sol";
import "./libraries/SafeMath8.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlucamonOwnership is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    BlucamonAirdrop
{
    using SafeMath for uint256;
    using SafeMath8 for uint8;

    constructor() ERC721("Blucamon", "BLUCAMON") {}

    modifier onlyOwnerOf(uint256 _id) {
        require(msg.sender == ownerOf(_id), "S_ONS_100");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function claimBlucamonEgg() external onlyAirdropWhitelist(msg.sender) {
        require(!isClaimedMapping[msg.sender], "S_ARD_103");
        claim(msg.sender);
        AirdropEggDetail memory eggDetail = getEggDetail();
        spawn(eggDetail.id, false, msg.sender, eggDetail.tokenUri);
    }

    function summon(uint256 _id) external onlySummoner {
        require(!blucamons[indexMapping[_id]].isSummoned, "S_SMN_100");
        summonBlucamon(_id);
    }

    function mintBlucamon(
        address _address,
        string memory _tokenUri,
        bool _isSummoned
    ) external onlySpawner {
        blucamonId = blucamonId.add(1);
        spawn(blucamonId, _isSummoned, _address, _tokenUri);
    }

    function spawn(
        uint256 _blucamonId,
        bool _isSummoned,
        address _address,
        string memory _tokenUri
    ) private {
        spawnBlucamon(_blucamonId, _isSummoned);
        _safeMint(_address, _blucamonId);
        _setTokenURI(_blucamonId, _tokenUri);
    }

    function breed(uint256 _blucamonId1, uint256 _blucamonId2)
        external
        onlyBreeder
    {
        require(isBreedable(_blucamonId1), "S_BRD_100");
        require(isBreedable(_blucamonId2), "S_BRD_100");
        Blucamon storage _blucamon1 = blucamons[indexMapping[_blucamonId1]];
        _blucamon1.elementalFragments = _blucamon1.elementalFragments.sub(1);
        Blucamon storage _blucamon2 = blucamons[indexMapping[_blucamonId2]];
        _blucamon2.elementalFragments = _blucamon2.elementalFragments.sub(1);
        emit BreedBlucamon(_blucamonId1, _blucamonId2);
    }

    function isBreedable(uint256 _blucamonId) private view returns (bool) {
        return blucamons[indexMapping[_blucamonId]].elementalFragments > 0;
    }
}
