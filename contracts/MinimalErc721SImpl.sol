// SPDX-License-Identifier: MIT
// Based on ERC721A Implementation.

import './ERC721S.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

pragma solidity ^0.8.10;

contract MinimalErc721SImpl is ERC721S, Ownable {

    constructor(
        DeploymentConfig memory config_ 
    ) ERC721S(config_) { }

    function mintAndStake(address to, uint256 quantity) public {
        require(_config.automaticStakeTimeOnMint > 0);
        _mint(to, quantity);
    }

    function mint(address to, uint256 quantity) public {
        _mint(to, quantity, false);
    }

    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1; 
    }

    // INTERNAL TESTING FUNCTIONS.
    function packStakingDataForMint(address owner) public view returns (uint256 result) {
        return _packStakingDataForMint(owner); 
    }

    function packOwnershipDataForTx(address newOwner, uint256 oldOwnership) public view returns (uint256 result) {
        return _packOwnershipDataForTx(newOwner, oldOwnership);
    }

    function updateOwnershipDataForStaking(uint256 oldOwnership, uint32 time) public view returns (uint256 result) {
        return _updateOwnershipDataForStaking(oldOwnership, time);
    }

}
