// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

// import '../MinimalErc721SImpl.sol';
import './ImmutabilityInvariants.sol';

contract StakingFreeInvariants is ImmutableMinimalErc721SImpl {

    DeploymentConfig conf = DeploymentConfig(
        0, // Min staking time.
        0, // Staking time on mint.
        0, // Staking time on tx.
        "TestToken",
        "TEST"
    );

    uint32 deploymentTime;

    constructor() MinimalErc721SImpl(conf) {
        deploymentTime = uint32(block.timestamp);
    }

    function echidna_immutable_config() public view returns (bool) {
        return configIsEqualTo(conf, deploymentTime);
    }
    
    function echidna_revert_on_staking_intent() public view returns (bool) {
        packStakingDataForMint(msg.sender);
        return true;
    }

    function echidna_ownerships_should_always_be_empty() public pure returns (bool) {
        // TODO 
        // _packedOwnershipOf(1);
        return true;
    }

}

