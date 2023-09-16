// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './ImmutabilityInvariants.sol';

contract StakingFreeInvariants is ImmutableMinimalErc721SImpl {

    DeploymentConfig conf = DeploymentConfig(
        0, // Min staking time.
        0, // Staking time on mint.
        0, // Staking time on tx.
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
        assert(false);
    }

    // If staking was never enabled, `totalStakedTime` should always be 0.
    function assert_empty_total_staked_time_on_tx(address newOwner, uint256 tokenId) public view {
        uint256 ownership = _packedOwnershipOf(tokenId);
        TokenOwnership memory newOwnership = _unpackedOwnership(
            packOwnershipDataForTx(newOwner, ownership)
        );
        assert(newOwnership.totalStakedTime == 0);
    }

    // If staking was never enabled, `stakingStart` should always be 0.
    function assert_empty_staking_start_on_tx(address newOwner, uint256 tokenId) public view {
        uint256 ownership = _packedOwnershipOf(tokenId);
        TokenOwnership memory newOwnership = _unpackedOwnership(
            packOwnershipDataForTx(newOwner, ownership)
        );
        assert(newOwnership.stakingStart == 0);
    }

    // If staking was never enabled, `stakingStart` should always be 0.
    function assert_empty_staking_time_on_tx(address newOwner, uint256 tokenId) public view {
        uint256 ownership = _packedOwnershipOf(tokenId);
        TokenOwnership memory newOwnership = _unpackedOwnership(
            packOwnershipDataForTx(newOwner, ownership)
        );
        assert(newOwnership.stakingDuration == 0);
    }

    // If staking was never enabled, all the packed ownership data should always be 0.
    function assert_empty_ownership_on_tx(address newOwner, uint256 tokenId) public view {
        uint256 ownership = _packedOwnershipOf(tokenId);
        uint256 newOwnership = packOwnershipDataForTx(newOwner, ownership);
        assert(newOwnership >> _BITPOS_TOTAL_STAKED_TIME == 0);
    }

    function assert_right_owner_on_tx_ownership_update(
        address newOwner, uint256 tokenId
    ) public view {
        uint256 ownership = _packedOwnershipOf(tokenId);
        TokenOwnership memory newOwnership = _unpackedOwnership(
            packOwnershipDataForTx(newOwner, ownership)
        );
        assert(newOwnership.owner == newOwner);
    }

    function assert_right_ownership_on_tx_after_disabling_staking(
        uint256 oldPackedOwnership,
        address newOwner
    ) public view {
        TokenOwnership memory oldOwnership = _unpackedOwnership(oldPackedOwnership);
        TokenOwnership memory newOwnership = _unpackedOwnership(
            packOwnershipDataForTx(newOwner, oldPackedOwnership)
        );
        assert(newOwnership.owner == newOwner);
        assert(newOwnership.stakingDuration == 0);
        assert(
            newOwnership.totalStakedTime ==
            oldOwnership.stakingDuration + oldOwnership.totalStakedTime
        );
    }

    function assert_empty_ownerships(uint256 tokenId) public view {
        require(_exists(tokenId));
        uint256 ownership = _packedOwnershipOf(tokenId);
        uint256 extraData = ownership >> 160; // Clear the address.
        assert(extraData == 0);
    }

    function assert_exluded_middle_ownership(uint256 tokenId) public view {
        uint256 ownership = _packedOwnerships[tokenId];
        // `ownership == 0` or `ownership == someAddress`. No staking data should
        // be packed in `ownership`.
        assert(
            ownership == 0 ||
            (address(uint160(ownership)) != address(0) && (ownership >> 160 == 0))
        );
    }


}

