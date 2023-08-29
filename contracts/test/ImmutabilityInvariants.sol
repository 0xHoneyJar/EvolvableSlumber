// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '../MinimalErc721SImpl.sol';

/**
 * @dev This abstract contract, intended to be iherited by other echidna
 * contracts, specifies invariants that are independent of the staking config.
 * See {StakingFreeInvariant.sol} for an example implementation. In this way,
 * we can specify different contracts with different staking configs, and still
 * be sure that the following invariants hold.
 */
abstract contract ImmutableMinimalErc721SImpl is MinimalErc721SImpl {

    address exampleOwner = address(0x1234);
    DeploymentConfig testConfig;
    uint32 deploymentTime;
    
    constructor(DeploymentConfig memory conf) MinimalErc721SImpl(conf) {
        mint(exampleOwner, 3);
        testConfig = conf; 
        deploymentTime = uint32(block.timestamp);
    }

    function echidna_immutable_config() public view returns (bool) {
        bytes32 packA = keccak256(abi.encodePacked(
            testConfig.minStakingTime, 
            testConfig.automaticStakeTimeOnMint,
            testConfig.automaticStakeTimeOnTx,
            testConfig.name,
            testConfig.symbol
        ));

        bytes32 packB = keccak256(abi.encodePacked(
            _config.minStakingTime, 
            _config.automaticStakeTimeOnMint,
            _config.automaticStakeTimeOnTx,
            _config.name,
            _config.symbol
        ));

        return packA == packB && deploymentTime == _config.deployTime;
    }

    function echidna_balance_lt_supply() public view returns (bool) {
        return balanceOf(msg.sender) <= totalSupply();
    }

    function echidna_next_token_id_eq_supply() public view returns (bool) {
        return _nextTokenId() == totalSupply() + _startTokenId();
    }

    function echidna_number_minted_lt_supply() public view returns (bool) {
        return _numberMinted(msg.sender) <= totalSupply();
    }

    function echidna_721a_non_initialized_slots() public view returns (bool) {
        return (
            _ownershipIsInitialized(1) &&
            !_ownershipIsInitialized(2) &&
            !_ownershipIsInitialized(3)
        );
    }

    function echidna_steal_ownership() public view returns (bool) {
        return (
            ownerOf(1) == exampleOwner &&
            ownerOf(2) == exampleOwner &&
            ownerOf(3) == exampleOwner
        );
    }

    function echidna_start_token_id_constant() public pure returns (bool) {
        return _startTokenId() == 1;
    }
    
}

