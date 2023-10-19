// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Relationship is ERC721Enumerable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant RootId = 100000000;
    address public constant RootWallet   = address(0x000000000000000000000000000000000000dEaD);

    // idRelations about relationId, its parent id stored at index 0.
    // RelationId => [ReputatonId]
    mapping(uint256 => EnumerableSet.UintSet) idRelations;
    // bind wallet and relationId
    // RelationId => [address]
    mapping(uint256 => EnumerableSet.AddressSet) idToWallets;
    // reverse bind from wallet to reputstionId
    // address => RelationId
    mapping(address => uint256) walletsToId;
    // which wallet used to receive benefit
    // relationId => address
    mapping(uint256 => address) beneficialWallets;

    error ParentExist(uint256 existParent, uint256 targetParent);
    error SonExist(uint256 parentId, uint256 sonId);

    event RelationBound(
        uint256 indexed parentId,
        uint256 indexed sonId,
        address indexed sonWallet
    );

    event BeneficialSet(
        uint256 indexed relationId,
        address indexed oldBeneficial,
        address indexed newBeneficial
    );

    function _bind(
        uint256 parentId,
        uint256 sonId,
        address sonWallet
    ) internal {
        if (idRelations[sonId].length() > 0)
            revert ParentExist(idRelations[sonId].at(0), parentId);
        idRelations[sonId].add(parentId);

        if (idRelations[parentId].contains(sonId))
            revert SonExist(parentId, sonId);
        idRelations[parentId].add(sonId);

        if (!idToWallets[sonId].contains(sonWallet)) idToWallets[sonId].add(sonWallet);

        walletsToId[sonWallet] = sonId;

        emit RelationBound(parentId, sonId, sonWallet);
    }

    constructor() ERC721("Bee Smart Relationship", "BSR") {
        _mint(RootWallet, RootId); // mint RootId to a black hold address
    }

    function nextId() public view returns(uint256) {
        return RootId + totalSupply();
    }

    // bind the parent and son relationship.
    // if soneId is 0, then we should mint a Relationship NFT for msg.sender at first.
    function bind(uint256 parendId, uint256 sonId) external {
        require(ownerOf(parendId) != address(0), "parent id not exist");
        if (sonId == 0) {
            require(balanceOf(msg.sender) == 0, "sender had BSR");
            sonId = nextId();
            // CAUTION: if msg.sender is a contract, it must make sure who can retrieve tokens from it.
            beneficialWallets[sonId] = msg.sender;

            _mint(msg.sender, sonId);
        } else {
            require(ownerOf(sonId) != address(0), "son id not exist");
        }

        _bind(parendId, sonId, msg.sender);
    }

    function setBeneficial(address wallet) external {
        require(wallet != address(0), "beneficial is 0");
        uint256 id = walletsToId[msg.sender];
        address oldBeneficial = beneficialWallets[id];
        require(oldBeneficial == msg.sender, "only old beneficial allowed");

        beneficialWallets[id] = wallet;

        emit BeneficialSet(id, oldBeneficial, wallet);
    }

    function getBeneficial(address wallet) external view returns(address) {
        uint256 id = walletsToId[wallet];
        return beneficialWallets[id];
    }

    function getRelationId(address wallet) external view returns(uint256) {
        return walletsToId[wallet];
    }

    function getWallets(uint256 relationId) external view returns(address[] memory) {
        // CAUTION: would bond too many wallets to enumerate, if happen
        return idToWallets[relationId].values();
    }

    //
    function getParentRelationId(address wallet, uint256 level) external view returns(uint256[] memory) {
        uint256[] memory ids = new uint256[](level);
        uint256 relationId = walletsToId[wallet];
        if (relationId == 0 || relationId == RootId) return ids;

        uint256 parendId;
        for (uint i = 0; i < level; ++i) {
            parendId = idRelations[relationId].at(0);
            if (parendId == RootId) break;
            ids[i] = parendId;

            relationId = parendId;
        }
        return ids;
    }

    function getParentBeneficials(address sonWallet, uint256 level) external view returns(address[] memory) {
        address[] memory wallets = new address[](level);

        uint256 relationId = walletsToId[sonWallet];
        if (relationId == 0 || relationId == RootId) return wallets;

        uint256 parendId;
        for (uint i = 0; i < level; ++i) {
            parendId = idRelations[relationId].at(0);
            if (parendId == RootId) break;
            wallets[i] = beneficialWallets[parendId];

            relationId = parendId;
        }
        return wallets;
    }
}