// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IRelationship {

    function getBeneficial(address wallet) external view returns(address);

    function getRelationId(address wallet) external view returns(uint256);

    function getWallets(uint256 relationId) external view returns(address[] memory) ;

    function getParentRelationId(address wallet) external view returns(uint256[] memory);

    function getParentBeneficials(address sonWallet) external view returns(address[] memory);
}