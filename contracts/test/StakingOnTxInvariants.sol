// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './ImmutabilityInvariants.sol';

contract StakingOnTxInvariants is ImmutableMinimalErc721SImpl {

    uint32 constant STAKING_TIME = 10; // 10 seconds.
    DeploymentConfig conf = DeploymentConfig(
        0, // Min staking time.
        0, // Staking time on mint.
        STAKING_TIME, // Staking time on tx.
        "TestToken",
        "TEST"
    );

    constructor() ImmutableMinimalErc721SImpl(conf) { }

    function assert_revert_on_mint_staking_intent(address owner) public view {
        packStakingDataForMint(owner);
        assert(false);
    }

    function assert_revert_on_staking_intent(uint256 ownership, uint32 time) public view {
        updateOwnershipDataForStaking(ownership, time);
        // If `minStakingTime == 0` that means staking is disabled, so
        // this code should be unrecheable, ie, the call above should
        // always revert.
        // TODO Use `.call` instead for better coverage reports.
        assert(false);
    }

    function assert_right_owner_on_tx(uint256 oldPackedOwnership, address newOwner) public view {
        TokenOwnership memory newOwnership = _unpackedOwnership(packOwnershipDataForTx(
            newOwner, oldPackedOwnership
        ));
        assert(newOwnership.owner == newOwner);
    }

    // TODO Check for unrealistic overflows.
    function assert_right_packed_total_staked_time_on_tx(uint256 oldPackedOwnership, address newOwner) public view {
        TokenOwnership memory oldOwnership = _unpackedOwnership(oldPackedOwnership);
        TokenOwnership memory newOwnership = _unpackedOwnership(packOwnershipDataForTx(
            newOwner, oldPackedOwnership
        ));
        assert(
            newOwnership.totalStakedTime ==
            oldOwnership.totalStakedTime + oldOwnership.stakingDuration
        );
    }

    // function assert_right_


}

