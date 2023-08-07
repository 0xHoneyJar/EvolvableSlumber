// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @dev This interface is used to implement a strategy pattern in the
 * evolution contract. One example of this strategy could be a logarithmic
 * function that makes each evolution harder to reach than the last.
 */
interface IEvolutionStrategy {
    /**
     * @notice Invariant \[
     *     \forall (s_1, s_2) \in \mathbb{N}^2:
     *         s_1 > s_2 \implies
     *             getEvolution(s_1) \geq getEvolution(s_2)    
     * \]
     */
    function getEvolution(uint256 stake) external view returns (uint256);
}
