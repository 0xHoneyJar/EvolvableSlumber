// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "erc721a/contracts/ERC721A.sol";

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

/**
 * Note that all those timestamps are enough to calculate any
 * possible staking strategy (any `StakingType`).
 */
struct StakeTokenInfo {
    bool isStaked;
    uint32 firstTimeStaked;
    uint32 totalTimeStaked;
    uint32 lastTimeStaked;
}

struct EvolutionConfig {
    StakingType evolutionStakeStrategy;
}


contract EvolutionArchetype is ERC721A {

    //StakingConfig public stakingConfig;
    mapping (uint256 => StakeTokenInfo) private _tokenIdToStakeInfo;

    constructor(
        string memory name,
        string memory ticker
    ) ERC721A(name, ticker) {}

    function mint(uint256 quantity) external payable {
        // TODO Add requires
        _mint(msg.sender, quantity);
    }

    function stake(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender);
        StakeTokenInfo memory stake = _tokenIdToStakeInfo[tokenId];
        uint32 currentTime = uint32(block.timestamp);

        if (stake.firstTimeStaked == 0) stake.firstTimeStaked = currentTime;
        stake.lastTimeStaked = currentTime;

        stake.isStaked = true;
        _tokenIdToStakeInfo[tokenId] = stake;
    }

    function unstake(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender);
        StakeTokenInfo memory stake = _tokenIdToStakeInfo[tokenId];

        require(stake.lastTimeStaked != 0);
        stake.totalTimeStaked += uint32(block.timestamp) - stake.lastTimeStaked;

        stake.isStaked = false;
        _tokenIdToStakeInfo[tokenId] = stake;
    }

    function getStake(
        uint256 tokenId, StakingType strategy
    ) public view returns (uint256) {
        StakeTokenInfo memory stake = _tokenIdToStakeInfo[tokenId];
        if (strategy == StakingType.CURRENT) 
            return block.timestamp - stake.lastTimeStaked;
        if (strategy == StakingType.ALIVE) 
            return block.timestamp - stake.firstTimeStaked;
        if (strategy == StakingType.CUMULATIVE) 
            return block.timestamp + stake.totalTimeStaked;
        return 0;
    }

}

