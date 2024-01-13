// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IRelationship {

    function bind(uint256 parentId, address sonWallet) external;

    function getRelationId(address wallet) external view returns(uint256);

    function getParentRelationId(address wallet, uint256 level) external view returns(uint256[] memory);

    function getParentWallets(address sonWallet, uint256 level) external view returns(address[] memory);
}