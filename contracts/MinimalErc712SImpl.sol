// SPDX-License-Identifier: MIT
// Based on ERC721A Implementation.

import './ERC721S.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

pragma solidity ^0.8.10;

contract MinimalErc721SImpl is ERC721S, Ownable {

    constructor(
        string memory name_,
        string memory symbol_,
        DeploymentConfig memory config_ 
    ) ERC721S(name_, symbol_, config_) { }

    function mintAndStake(address to, uint256 quantity) public onlyOwner {
        _mint(to, quantity);
    }

    function mint(address to, uint256 quantity) public onlyOwner {
        _mint(to, quantity, false);
    }

    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1; 
    }


}
