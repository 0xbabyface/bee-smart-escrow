// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSDC is ERC20 {

    constructor() ERC20("Test USDC", "USDC") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
