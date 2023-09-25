// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./RelationshipBase.sol";

contract Relationship is ERC721Enumerable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant RootParentId = 100000000000;
    address public constant RootWallet   = address(0x000000000000000000000000000000000000dEaD);

    uint256 public constant MaxParentsLevel = 5;

    // relations about reputationId, its parent id stored at index 0.
    // ReputationId => [ReputatonId]
    mapping(uint256 => EnumerableSet.UintSet) relations;
    // bind wallet and reputationId
    // ReputationId => [address]
    mapping(uint256 => EnumerableSet.AddressSet) idToWallets;
    // reverse bind from wallet to reputstionId
    // address => ReputationId
    mapping(address => uint256) walletsToId;
    // which wallet used to receive benefit
    // reputationId => address
    mapping(uint256 => address) beneficialWallets;

    error ParentExist(uint256 existParent, uint256 targetParent);
    error SonExist(uint256 parentId, uint256 sonId);

    event RelationBound(
        uint256 indexed parentId,
        uint256 indexed sonId,
        address indexed sonWallet
    );

    event BeneficialSet(
        uint256 indexed reputationId,
        address indexed oldBeneficial,
        address indexed newBeneficial
    );

    function _bind(
        uint256 parentId,
        uint256 sonId,
        address sonWallet
    ) internal {
        if (relations[sonId].length() > 0)
            revert ParentExist(relations[sonId].at(0), parentId);
        relations[sonId].add(parentId);

        if (relations[parentId].contains(sonId))
            revert SonExist(parentId, sonId);
        relations[parentId].add(sonId);

        if (!idToWallets[sonId].contains(sonWallet)) idToWallets[sonId].add(sonWallet);

        walletsToId[sonWallet] = sonId;

        emit RelationBound(parentId, sonId, sonWallet);
    }

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
            require(balanceOf(msg.sender) == 0, "sender had BSP");
            sonId = nextId();
            // CAUTION: if msg.sender is a contract, it must make sure who can retrieve tokens from it.
            beneficialWallets[sonId] = msg.sender;

            _mint(msg.sender, sonId);
        } else {
            require(ownerOf(sonId) != address(0), "son id not exist");
        }

        _bind(parendId, sonId, msg.sender);
    }

    function setBeneficialWallet(address beneficial) external {
        require(beneficial != address(0), "beneficial is 0");
        uint256 id = walletsToId[msg.sender];
        address oldBeneficial = beneficialWallets[id];
        require(oldBeneficial == msg.sender, "only old beneficial allowed");

        beneficialWallets[id] = beneficial;

        emit BeneficialSet(id, oldBeneficial, beneficial);
    }

    function getBeneficialWallets(address sonWallet) public view returns(address[] memory) {
        address[] memory wallets = new address[](MaxParentsLevel);

        uint256 reputationId = walletsToId[sonWallet];
        if (reputationId == 0 || reputationId == RootParentId) return wallets;

        uint256 parendId;
        for (uint i = 0; i < MaxParentsLevel; ++i) {
            parendId = relations[reputationId].at(0);
            if (parendId == RootParentId) break;
            wallets[i] = beneficialWallets[parendId];

            reputationId = parendId;
        }
        return wallets;
    }
}