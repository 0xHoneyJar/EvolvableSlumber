// SPDX-License-Identifier: MIT

import "./../interfaces/IEvolutionStrategy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import { FixedPointMathLib as Math } from "solady/src/utils/FixedPointMathLib.sol";

pragma solidity ^0.8.10;

/**
 * @dev This PoC evolution strategy will generally require `n` days staked 
 *      and `n` interactions to achieve level `n//10`. Thus, for example, if
 *      some token was interacted with 49 times, and was staked for 50 days,
 *      then its level will be 4, and 5 after another extra interaction.
 */
contract InteractiveEvolutionStrategy is IEvolutionStrategy {

    address private _interactiveNft;
    mapping (uint256 => uint16) private _interactions;

    constructor (address interactiveNft) {
        _interactiveNft = interactiveNft;
    }

    function interact(uint256 tokenId) public {
        require(IERC721(_interactiveNft).ownerOf(tokenId) == msg.sender); 
        _interactions[tokenId] += 1;
    }

    function getInteractions(uint256 tokenId) public view returns (uint16) {
        return _interactions[tokenId];
    }

    function getEvolution(uint256 stake, uint256 tokenId) external view returns (uint256) {
        return Math.min(stake/1 days, _interactions[tokenId]) / 10 days;
    }
}

