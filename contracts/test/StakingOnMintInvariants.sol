// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './ImmutabilityInvariants.sol';

contract StakingOnMintInvariants is ImmutableMinimalErc721SImpl {

    uint32 constant STAKING_TIME = 10; // 10 seconds.
    DeploymentConfig conf = DeploymentConfig(
        0, // Min staking time.
        STAKING_TIME, // Staking time on mint.
        0, // Staking time on tx.
        "TestToken",
        "TEST"
    );

    constructor() ImmutableMinimalErc721SImpl(conf) { }

    function assert_right_packed_owner_on_mint(address owner) public view {
        TokenOwnership memory ownership = _unpackedOwnership(packStakingDataForMint(owner));
        assert(ownership.owner == owner);
    }

    function assert_revert_on_staking_intent(uint256 ownership, uint32 time) public view {
        updateOwnershipDataForStaking(ownership, time);
        // If `minStakingTime == 0` that means staking is disabled, so
        // this code should be unrecheable, ie, the call above should
        // always revert.
        assert(false);
    }

    function assert_right_total_staked_time_on_mint(address owner) public view {
        TokenOwnership memory ownership = _unpackedOwnership(packStakingDataForMint(owner));
        assert(ownership.totalStakedTime == 0);
    }

    function assert_right_stataking_start_on_mint(address owner) public view {
        uint256 relativeStakingStart = block.timestamp - _config.deployTime;
        TokenOwnership memory ownership = _unpackedOwnership(packStakingDataForMint(owner));
        assert(ownership.stakingStart == relativeStakingStart);
    }

    function assert_right_stataking_start_on_later_mint(address owner) public view {
        uint256 relativeStakingStart = block.timestamp - _config.deployTime;
        require(relativeStakingStart > 0);
        TokenOwnership memory ownership = _unpackedOwnership(packStakingDataForMint(owner));
        assert(ownership.stakingStart == relativeStakingStart);
    }

    function assert_right_staking_time_on_staking_mint(address owner, uint256 quantity) public {
        require(quantity > 0 && quantity < 10 && owner != address(0));
        uint256 nextTokenId = _nextTokenId();
        mintAndStake(owner, quantity);
        for (uint256 i = 0; i < quantity; i++) {
            TokenOwnership memory ownership = _unpackedOwnership(_packedOwnershipOf(nextTokenId + i));
            assert(ownership.stakingDuration == STAKING_TIME);
        }
    }

    function assert_right_staking_time_on_normal_mint(address owner, uint256 quantity) public {
        require(quantity > 0 && quantity < 10 && owner != address(0));
        uint256 nextTokenId = _nextTokenId();
        mint(owner, quantity);
        for (uint256 i = 0; i < quantity; i++) {
            TokenOwnership memory ownership = _unpackedOwnership(_packedOwnershipOf(nextTokenId + i));
            assert(ownership.stakingDuration == 0);
        }
    }

    function assert_cant_tx_if_staked_because_of_mint(address newOwner) public {
        uint256 id = _nextTokenId();
        mintAndStake(msg.sender, 1);
        safeTransferFrom(msg.sender, newOwner, id);
        assert(false);
    }

    function assert_right_ownership_after_tx(uint256 oldPackedOwnership, address newOwner) public view {
        TokenOwnership memory oldOwnership = _unpackedOwnership(oldPackedOwnership);
        TokenOwnership memory newOwnership = _unpackedOwnership(
            packOwnershipDataForTx(newOwner, oldPackedOwnership)
        );

        assert(newOwnership.owner == newOwner);
        assert(
            newOwnership.totalStakedTime == 
            oldOwnership.totalStakedTime + oldOwnership.stakingDuration
        );
        
        assert(newOwnership.stakingDuration == 0);
        assert(newOwnership.stakingStart == 0);
    }

}

