// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Candy is Ownable, ERC20 {

    mapping(address => bool) public minters;

    event MinterSet(address indexed owner, address indexed minter, bool asMinter);

    modifier onlyMinters() {
        require(minters[msg.sender], "only minters");
        _;
    }

    constructor() ERC20("Bee Smart Candy", "CANDY") {}

    function setMinter(address minter, bool asMinter) external onlyOwner {
        minters[minter] = asMinter;
        emit MinterSet(msg.sender, minter, asMinter);
    }

    function mint(address to, uint256 amount) external onlyMinters {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyMinters {
        _burn(from, amount);
    }

}