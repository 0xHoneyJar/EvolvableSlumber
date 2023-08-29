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

    function echidna_revert_on_mint_staking_intent() public view returns (bool) {
        packStakingDataForMint(msg.sender);
        return true;
    }

    function assert_revert_on_staking_intent(uint256 ownership, uint32 time) public view {
        updateOwnershipDataForStaking(ownership, time);
        // If `minStakingTime == 0` that means staking is disabled, so
        // this code should be unrecheable, ie, the call above should
        // always revert.
        assert(false);
    }

    function assert_empty_ownership_on_tx(address newOwner, uint256 tokenId) public view {
        uint256 ownership = _packedOwnershipOf(tokenId);
        uint256 newOwnership = packOwnershipDataForTx(newOwner, ownership);
        assert(address(uint160(newOwnership)) == newOwner);
        assert(newOwnership >> 160 == 0);
    }

    function assert_empty_ownerships(uint256 tokenId) public view {
        if (_exists(tokenId)) {
            uint256 ownership = _packedOwnershipOf(tokenId);
            uint256 extraData = ownership >> 160; // Clear the address.
            assert(extraData == 0);
        }
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

