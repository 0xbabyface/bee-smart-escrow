// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ShareCard is ERC721 {

    address public initReceiver = 0x1eF6E29cC8A97b96b02430465980996e05E51726;

    constructor() ERC721("SE share card", "SESC") {

        for (uint256 i = 1; i <= 32; i++) {
            _mint(initReceiver, i);
        }
    }
}