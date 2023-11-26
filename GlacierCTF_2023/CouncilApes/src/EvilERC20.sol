// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8;

import "./ERC20.sol";

contract EvilErc20 is ERC20{
    constructor(address owner, string memory name, string memory symbol) ERC20(name, symbol) 
    {
        _mint(owner, 100_000_000 - 1); 
    }
}