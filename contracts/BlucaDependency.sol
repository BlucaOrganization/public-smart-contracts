// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract BlucaDependency {
    address public whitelistSetterAddress;

    mapping(address => bool) public whitelistedSpawner;
    mapping(address => bool) public whitelistedBreeder;
    mapping(address => bool) public whitelistedFounder;
    mapping(address => bool) public whitelistedSummoner;
    mapping(address => bool) public whitelistedAirdropSetter;

    constructor() {
        whitelistSetterAddress = msg.sender;
    }

    modifier onlyWhitelistSetter() {
        require(msg.sender == whitelistSetterAddress, "S_PMS_100");
        _;
    }

    modifier onlySpawner() {
        require(whitelistedSpawner[msg.sender], "S_PMS_101");
        _;
    }

    modifier onlyBreeder() {
        require(whitelistedBreeder[msg.sender], "S_PMS_103");
        _;
    }

    modifier onlyAirdropSetter() {
        require(whitelistedAirdropSetter[msg.sender], "S_PMS_102");
        _;
    }

    modifier onlyFounder() {
        require(whitelistedFounder[msg.sender], "S_PMS_104");
        _;
    }

    modifier onlySummoner() {
        require(whitelistedSummoner[msg.sender], "S_PMS_105");
        _;
    }

    function setWhitelistSetter(address _newSetter)
        external
        onlyWhitelistSetter
    {
        whitelistSetterAddress = _newSetter;
    }

    function setSpawner(address _spawner, bool _isWhitelisted)
        external
        onlyWhitelistSetter
    {
        whitelistedSpawner[_spawner] = _isWhitelisted;
    }

    function setBreeder(address _breeder, bool _isWhitelisted)
        external
        onlyWhitelistSetter
    {
        whitelistedBreeder[_breeder] = _isWhitelisted;
    }

    function setAirdropSetter(address _airdropSetter, bool _isWhitelisted)
        external
        onlyWhitelistSetter
    {
        whitelistedAirdropSetter[_airdropSetter] = _isWhitelisted;
    }

    function setFounder(address _founder, bool _isWhitelisted)
        external
        onlyWhitelistSetter
    {
        whitelistedFounder[_founder] = _isWhitelisted;
    }

    function setSummoner(address _summoner, bool _isWhitelisted)
        external
        onlyWhitelistSetter
    {
        whitelistedSummoner[_summoner] = _isWhitelisted;
    }
}
