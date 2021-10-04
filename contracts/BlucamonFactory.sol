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
    }

    Blucamon[] public blucamons;
    uint256 public blucamonId = 0;
    uint8 defaultElementalFragments = 5;

    mapping(uint256 => uint256) indexMapping;

    function setDefaultElementalFragments(uint8 _newValue)
        external
        onlySpawner
    {
        defaultElementalFragments = _newValue;
    }

    function spawnBlucamon(uint256 _id, bool _isSummoned) internal {
        blucamons.push(Blucamon(_isSummoned, defaultElementalFragments));
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
