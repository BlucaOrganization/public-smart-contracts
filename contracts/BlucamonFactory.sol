// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BlucaDependency.sol";

abstract contract BlucamonFactory is BlucaDependency {
    event SpawnBlucamon(uint256 blucamonId);
    event SpawnBlucamonEgg(uint256 blucamonId);
    event SummonBlucamon(uint256 blucamonId);
    event BreedBlucamon(uint256 blucamonId1, uint256 blucamonId2);

    struct Blucamon {
        bool isSummoned;
        uint8 elementalFragments;
        uint8 rarity;
        uint256 blucadexId;
        uint8 eggElement;
    }

    uint8 public defaultElementalFragments = 5;

    Blucamon[] public blucamons;
    uint256 public blucamonId = 0;
    mapping(uint256 => uint256) public indexMapping;

    function getBlucamonCount() public view returns (uint256) {
        return blucamons.length;
    }

    function getBlucamonId() public view returns (uint256) {
        return blucamonId;
    }

    function setBlucamonId(uint256 _newBlucamonId) external onlySpawner {
        blucamonId = _newBlucamonId;
    }

    function getDefaultElementalFragments() public view returns (uint8) {
        return defaultElementalFragments;
    }

    function setDefaultElementalFragments(uint8 _newValue)
        external
        onlySpawner
    {
        defaultElementalFragments = _newValue;
    }

    function spawnBlucamon(
        uint256 _id,
        bool _isSummoned,
        uint8 _rarity,
        uint256 _blucadexId,
        uint8 _eggElement
    ) internal {
        blucamons.push(
            Blucamon(
                _isSummoned,
                defaultElementalFragments,
                _rarity,
                _blucadexId,
                _eggElement
            )
        );
        indexMapping[_id] = blucamons.length - 1;
        if (_isSummoned) {
            emit SpawnBlucamon(_id);
        } else {
            emit SpawnBlucamonEgg(_id);
        }
    }

    function summonBlucamon(uint256 _id) internal {
        Blucamon storage _blucamon = blucamons[indexMapping[_id]];
        _blucamon.isSummoned = true;
        emit SummonBlucamon(_id);
    }
}
