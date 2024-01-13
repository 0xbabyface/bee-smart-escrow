// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IRelationship.sol";

contract Relationship is IRelationship {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct R {
        uint256               parentId;
        address               wallet;
        EnumerableSet.UintSet sonsId;
    }

    uint256 public constant RootId = 100000000;
    address public constant RootWallet   = address(0x000000000000000000000000000000000000dEaD);

    // RelationId => R
    mapping(uint256 => R) idRelations;
    // reverse bind from wallet to reputstionId
    // address => RelationId
    mapping(address => uint256) walletsToId;

    uint256 public totalSupply;

    address public beeSmart;

    event RelationBound(
        uint256 indexed parentId,
        uint256 indexed myId,
        address indexed myWallet
    );

    modifier onlySmart() {
        require(msg.sender == beeSmart, "Relationship: only smart");
        _;
    }

    constructor(address smart) {
        beeSmart = smart;
    }

    function nextId() internal returns(uint256) {
        ++totalSupply;
        return RootId + totalSupply;
    }

    // bind the parent and son relationship.
    // if soneId is 0, then we should mint a Relationship NFT for msg.sender at first.
    function bind(uint256 parentId, address sonWallet) external onlySmart {
        require(walletsToId[sonWallet] == 0, "already bound");
        require(parentId == RootId || idRelations[parentId].parentId != 0, "parent not exist");

        uint256 myId = nextId();

        R storage r = idRelations[myId];
        r.parentId = parentId;
        r.wallet   = sonWallet;

        idRelations[parentId].sonsId.add(myId);

        walletsToId[sonWallet] = myId;

        emit RelationBound(parentId, myId, sonWallet);
    }

    function getRelationId(address wallet) external view returns(uint256) {
        return walletsToId[wallet];
    }

    function getParentRelationId(address wallet, uint256 level) external view returns(uint256[] memory) {
        uint256[] memory ids = new uint256[](level);
        uint256 relationId = walletsToId[wallet];
        if (relationId == 0 || relationId == RootId) return ids;

        uint256 parentId;
        for (uint i = 0; i < level; ++i) {
            parentId = idRelations[relationId].parentId;
            if (parentId == RootId) break;
            ids[i] = parentId;

            relationId = parentId;
        }
        return ids;
    }

    function getParentWallets(address sonWallet, uint256 level) external view returns(address[] memory) {
        address[] memory wallets = new address[](level);

        uint256 relationId = walletsToId[sonWallet];
        if (relationId == 0 || relationId == RootId) return wallets;

        uint256 parentId;
        for (uint i = 0; i < level; ++i) {
            parentId = idRelations[relationId].parentId;
            if (parentId == RootId) break;
            wallets[i] = idRelations[parentId].wallet;

            relationId = parentId;
        }
        return wallets;
    }
}