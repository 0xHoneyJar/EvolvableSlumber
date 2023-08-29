// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '../MinimalErc721SImpl.sol';

abstract contract ImmutableMinimalErc721SImpl is MinimalErc721SImpl {

    function configIsEqualTo(
        DeploymentConfig memory conf, uint32 deploymentTime
    ) public view returns (bool) {
        bytes32 packA = keccak256(abi.encodePacked(
            conf.minStakingTime, 
            conf.automaticStakeTimeOnMint,
            conf.automaticStakeTimeOnTx,
            conf.name,
            conf.symbol
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

    function echidna_next_token_id_equal_to_supply() public view returns (bool) {
        return _nextTokenId() == totalSupply() + _startTokenId();
    }

    function echidna_number_minted_lt_supply() public view returns (bool) {
        return _numberMinted(msg.sender) <= totalSupply();
    }

    function echidna_721a_non_initialized_slots() public returns (bool) {
        uint256 nextId = _nextTokenId();
        mint(msg.sender, 2);
        return _ownershipIsInitialized(nextId) && !_ownershipIsInitialized(nextId + 1);
    }
    
}

