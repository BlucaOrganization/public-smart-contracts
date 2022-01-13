// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract BlucaDependency {
    address public whitelistSetterAddress;

    mapping(address => bool) public whitelistedSpawner;
    mapping(address => bool) public whitelistedBreeder;
    mapping(address => bool) public whitelistedFounder;
    mapping(address => bool) public whitelistedSummoner;
    mapping(address => bool) public whitelistedAirdropSetter;
    mapping(address => bool) public whitelistedFactorySetter;

    event SetWhitelistSetter(address _newSetter);
    event SetSpawner(address _spawner, bool _isWhitelisted);
    event SetBreeder(address _breeder, bool _isWhitelisted);
    event SetAirdropSetter(address _airdropSetter, bool _isWhitelisted);
    event SetFounder(address _founder, bool _isWhitelisted);
    event SetSummoner(address _summoner, bool _isWhitelisted);
    event SetFactorySetter(address _factorySetter, bool _isWhitelisted);

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

    modifier onlyFactorySetter() {
        require(whitelistedFactorySetter[msg.sender], "S_PMS_106");
        _;
    }

    function setWhitelistSetter(address _newSetter)
        external
        onlyWhitelistSetter
    {
        whitelistSetterAddress = _newSetter;
        emit SetWhitelistSetter(_newSetter);
    }

    function setSpawner(address _spawner, bool _isWhitelisted)
        external
        onlyWhitelistSetter
    {
        whitelistedSpawner[_spawner] = _isWhitelisted;
        emit SetSpawner(_spawner, _isWhitelisted);
    }

    function setBreeder(address _breeder, bool _isWhitelisted)
        external
        onlyWhitelistSetter
    {
        whitelistedBreeder[_breeder] = _isWhitelisted;
        emit SetBreeder(_breeder, _isWhitelisted);
    }

    function setAirdropSetter(address _airdropSetter, bool _isWhitelisted)
        external
        onlyWhitelistSetter
    {
        whitelistedAirdropSetter[_airdropSetter] = _isWhitelisted;
        emit SetAirdropSetter(_airdropSetter, _isWhitelisted);
    }

    function setFounder(address _founder, bool _isWhitelisted)
        external
        onlyWhitelistSetter
    {
        whitelistedFounder[_founder] = _isWhitelisted;
        emit SetFounder(_founder, _isWhitelisted);
    }

    function setSummoner(address _summoner, bool _isWhitelisted)
        external
        onlyWhitelistSetter
    {
        whitelistedSummoner[_summoner] = _isWhitelisted;
        emit SetSummoner(_summoner, _isWhitelisted);
    }

    function setFactorySetter(address _factorySetter, bool _isWhitelisted)
        external
        onlyWhitelistSetter
    {
        whitelistedFactorySetter[_factorySetter] = _isWhitelisted;
        emit SetFactorySetter(_factorySetter, _isWhitelisted);
    }
}
