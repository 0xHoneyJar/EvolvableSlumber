// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @dev This interface is used to implement a strategy pattern in the
 * evolution contract. One example of this strategy could be a logarithmic
 * function that makes each evolution harder to reach than the last.
 */
interface IEvolutionStrategy {
    function getEvolution(uint256 stake, uint256 tokenId) external view returns (uint256);
}
