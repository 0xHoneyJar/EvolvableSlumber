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
    
    function assert_non_empty_packed_ownership(uint256 tokenId) public view {
        // It should revert if `ownership == 0`.
        uint256 ownership = _packedOwnershipOf(tokenId);
        assert(ownership != 0);
    }

    // Should I fuzz statefull code like this? Wont it confuse the fuzzer?
    function assert_right_ownership_on_non_staked_mint(
        address owner, uint256 quantity
    ) public {
        require(quantity < 10 && quantity > 0 && owner != address(0));
        uint256 nextTokenId = _nextTokenId();
        mint(owner, quantity);
        // NOTE That the `owner` could always transfer any owned token,
        // but this invariant wont break because its atomic.
        for (uint256 i = 0; i < quantity; i++)
            assert(ownerOf(nextTokenId + i) == owner);
    }

    function assert_right_ownership_on_staked_mint(
        address owner, uint256 quantity
    ) public {
        require(quantity < 10 && quantity > 0 && owner != address(0));
        uint256 nextTokenId = _nextTokenId();
        // Will revert if staking not enabled.
        mintAndStake(owner, quantity);
        // NOTE That the `owner` could always transfer any owned token,
        // but this invariant wont break because its atomic.
        for (uint256 i = 0; i < quantity; i++)
            assert(ownerOf(nextTokenId + i) == owner);
    }

    function assert_right_ownership_on_non_staked_self_mint() public {
        uint256 nextTokenId = _nextTokenId();
        mint(msg.sender, 1);
        assert(ownerOf(nextTokenId) == msg.sender);
    }

    function assert_right_ownership_on_staked_self_mint() public {
        uint256 nextTokenId = _nextTokenId();
        // Will revert if staking not enabled.
        mintAndStake(msg.sender, 1);
        assert(ownerOf(nextTokenId) == msg.sender);
    }

    function assert_cant_transfer_on_staked(uint256 tokenId, address newOwner) public {
        require(ownerOf(tokenId) == msg.sender); 
        TokenOwnership memory ownership = _unpackedOwnership(_packedOwnershipOf(tokenId));
        uint256 stakingEnd = _config.deployTime + ownership.stakingDuration;

        require(stakingEnd > block.timestamp);
        // If the token is staked, this line should always revert.
        safeTransferFrom(msg.sender, newOwner, tokenId);
        assert(false);
    }

}

