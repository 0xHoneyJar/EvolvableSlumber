// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISharesHolder.sol";
import "./interfaces/IEvolutionStrategy.sol";
import "solady/src/utils/LibString.sol";

/**
 * NONE: Staking disabled.
 * CURRENT: Stake linear to the time the token was last time staked.
 * ALIVE: Stake linear to the time the token was staked for the first time.
 * CUMULATIVE: Stake linear to the sum of all staking times. E.g, if you staked
 * for 3 days, unstaked, and restaked for another day, the total stake will
 * be linearly proportional to 4.
 */
enum StakingType {
    NONE, CURRENT, ALIVE, CUMULATIVE
}

// TODO How do I automatically stake on mint without breaking 721A?
// TODO How do I automatically stake on tx without blaoting the UX?
//      This second one is easier.
struct StakingConfig {
    uint32 minStakingTime;
    uint32 automaticStakeTimeOnMint;
    uint32 automaticStakeTimeOnTx;
}

/**
 * Note that all those timestamps are enough to calculate any
 * possible staking strategy (any `StakingType`).
 * Note also that the actual total time staked will be:
 *     `totalTimeStaked + (block.timestamp - lastTimeStaked)`
 * Because this value is dynamic and depends on the chain state.
 */
struct StakeTokenInfo {
    bool isStaked;
    // TODO Slightly redundant state: \[
    //    totalTimeStaked = 0 \implies
    //        firstTimeStaked = lastTimeStaked
    // /]
    // TODO ERC721A Holds info about the timestamp a token was staked.
    uint32 firstTimeStaked;
    uint32 totalTimeStaked;
    uint32 lastTimeStaked;
}

struct EvolutionConfig {
    StakingType evolutionStakeStrategy;
    address evolutionResolverStrategy;
}

struct RewardsConfig {
    StakingType rewardsTakeStrategy;
}

struct GeneralConfig {
    uint256 price;
    string baseUri;
}

contract ImmutableEvolutionArchetype is ERC721A, Ownable {

    StakingConfig private _stakingConfig;
    mapping (uint256 => StakeTokenInfo) private _tokenIdToStakeInfo;

    EvolutionConfig private _evolutionConfig;
    RewardsConfig private _rewardsConfig;
    GeneralConfig private _config;

    bool private _initialized;

    constructor(
        string memory name,
        string memory ticker
    ) ERC721A(name, ticker) {}
    
    function initialize(
        StakingConfig memory stakingConfig,
        EvolutionConfig memory evolutionConfig,
        RewardsConfig memory rewardsConfig,
        GeneralConfig memory config 
    ) public onlyOwner {
        require(!_initialized);

        _stakingConfig = stakingConfig;
        _evolutionConfig = evolutionConfig;
        _rewardsConfig = rewardsConfig;
        _config = config;

        _initialized = true;
    }

    function mint(uint16 quantity) external payable {
        require(msg.value >= _config.price * quantity);

        uint256 fstNextId = _nextTokenId();
        _mint(msg.sender, quantity);
        if (_stakingConfig.automaticStakeTimeOnMint > 0)
            _setExtraDataAt(fstNextId, 1);

    }

    function getTokenStakedOnMint(uint256 tokenId) public view returns (bool) {
        return _ownershipOf(tokenId).extraData == 1;
    }

    function stake(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender);
        StakeTokenInfo memory currentStake = _tokenIdToStakeInfo[tokenId];
        require(!currentStake.isStaked);
        uint32 currentTime = uint32(block.timestamp);

        if (currentStake.firstTimeStaked == 0) currentStake.firstTimeStaked = currentTime;
        currentStake.lastTimeStaked = currentTime;

        currentStake.isStaked = true;
        _tokenIdToStakeInfo[tokenId] = currentStake;
    }

    function unstake(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender);
        StakeTokenInfo memory currentStake = _tokenIdToStakeInfo[tokenId];
        require(currentStake.isStaked);

        currentStake.totalTimeStaked += uint32(block.timestamp) - currentStake.lastTimeStaked;

        currentStake.isStaked = false;
        _tokenIdToStakeInfo[tokenId] = currentStake;
    }

    function getStake(
        uint256 tokenId, StakingType strategy
    ) public view returns (uint256) {
        StakeTokenInfo memory currentStake = _tokenIdToStakeInfo[tokenId];
        if (strategy == StakingType.CURRENT) 
            return block.timestamp - currentStake.lastTimeStaked;
        if (strategy == StakingType.ALIVE) 
            return block.timestamp - currentStake.firstTimeStaked;
        if (strategy == StakingType.CUMULATIVE) 
            return (block.timestamp - currentStake.lastTimeStaked) + currentStake.totalTimeStaked;
        return 0;
    }
    
    function getEvolution(uint256 tokenId) public view returns (uint256) {
        uint256 currentStake = getStake(tokenId, _evolutionConfig.evolutionStakeStrategy);
        return IEvolutionStrategy(
            _evolutionConfig.evolutionResolverStrategy
        ).getEvolution(currentStake);
    }

    function tokenURI(uint256 tokenId) 
        public 
        view
        virtual
        override
        returns (string memory)
    {
        if (bytes(_config.baseUri).length == 0) return "";
        return string(abi.encodePacked(
            _config.baseUri,
            LibString.toString(getEvolution(tokenId)),
            "/",
            LibString.toString(tokenId)
        ));
    }

}

