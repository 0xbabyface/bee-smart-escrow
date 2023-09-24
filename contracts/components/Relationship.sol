// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./RelationshipBase.sol";

contract Relationship is ERC721Enumerable, RelationshipBase {

    uint256 public constant RootParentId = 100000000000;
    address public constant RootWallet   = address(0x000000000000000000000000000000000000dEaD);

    constructor() ERC721("Bee Smart Reputation", "BSP") {
        _mint(RootWallet, RootParentId); // mint RootParentId to a black hold address
    }

    function nextId() public view returns(uint256) {
        return RootParentId + totalSupply();
    }

    // bind the parent and son relationship.
    // if soneId is 0, then we should mint a Reputation NFT for msg.sender at first.
    function bind(uint256 parendId, uint256 sonId) external {
        require(ownerOf(parendId) != address(0), "parent id not exist");
        if (sonId == 0) {
            sonId = nextId();
            _mint(msg.sender, sonId);
        } else {
            require(ownerOf(sonId) != address(0), "son id not exist");
        }

        _bind(parendId, sonId, msg.sender);
    }
}