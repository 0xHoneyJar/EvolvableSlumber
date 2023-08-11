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
 * ALIVE: Stake linear to the time the token was minted.
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
    // NOTE That the token could get automatically staked on mint,
    // then this variable will be set 
    uint32 lastTimeStaked;
    uint32 totalTimeStaked;
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

        // If tokens should get staked automatically on mint,
        // set a flag so the contract knows it happened.
        if (_stakingConfig.automaticStakeTimeOnMint > 0)
            _setExtraDataAt(fstNextId, 1);
    }

    function getTokenStakedOnMint(uint256 tokenId) public view returns (bool) {
        return _ownershipOf(tokenId).extraData == 1;
    }

    function getMintTime(uint256 tokenId) public view returns (uint256) {
        return _ownershipOf(tokenId).startTimestamp;
    }

    /**
     * @notice Theres no `unstake` function, tokens get automatically unstaked
     * when its time.
     */
    function getTokenIsCurrentlyStaked(uint256 tokenId) public view returns (bool) {
        if (getTokenStakedOnMint(tokenId)) {
            uint256 stakingEnd = getMintTime(tokenId) + _stakingConfig.automaticStakeTimeOnMint;
            if (stakingEnd > block.timestamp) return true;
        }

        StakeTokenInfo memory currentStake = _tokenIdToStakeInfo[tokenId];
        if (currentStake.lastTimeStaked > 0) {
            uint256 stakingEnd = getMintTime(tokenId) + _stakingConfig.minStakingTime;
            return stakingEnd > block.timestamp;
        }

        return false;
    }

    function stake(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender);
        require(!getTokenIsCurrentlyStaked(tokenId));

        // NOTE All this code is terrible, but it works.
        // TODO Learn more about ERC721A to see how can I batch all together.
        StakeTokenInfo memory currentStake = _tokenIdToStakeInfo[tokenId];
        uint32 currentTime = uint32(block.timestamp);

        currentStake.lastTimeStaked = currentTime;
        _tokenIdToStakeInfo[tokenId] = currentStake;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // NOTE This will break because of `quantity`.
        // TODO Learn more about ERC721A to see how can I batch all together.
        require(!getTokenIsCurrentlyStaked(startTokenId));
    }

    function getStake(
        uint256 tokenId, StakingType strategy
    ) public view returns (uint256) {
        StakeTokenInfo memory currentStake = _tokenIdToStakeInfo[tokenId];
        if (strategy == StakingType.CURRENT) 
            return block.timestamp - currentStake.lastTimeStaked;
        if (strategy == StakingType.ALIVE) 
            return block.timestamp - getMintTime(tokenId);
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

