// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RelationshipBase {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    // relations about reputationId, its parent id stored at index 0.
    // ReputationId => [ReputatonId]
    mapping(uint256 => EnumerableSet.UintSet) relations;
    // bind wallet and reputationId
    // ReputationId => [address]
    mapping(uint256 => EnumerableSet.AddressSet) wallets;
    // reverse bind from wallet to reputstionId
    // address => ReputationId
    mapping(address => uint256) walletsToId;

    error ParentExist(uint256 existParent, uint256 targetParent);
    error SonExist(uint256 parentId, uint256 sonId);

    event RelationBound(
        uint256 indexed parentId,
        uint256 indexed sonId,
        address indexed sonWallet
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

        if (!wallets[sonId].contains(sonWallet)) wallets[sonId].add(sonWallet);

        walletsToId[sonWallet] = sonId;

        emit RelationBound(parentId, sonId, sonWallet);
    }
}
