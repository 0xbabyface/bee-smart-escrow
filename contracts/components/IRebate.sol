// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IRebate {
    function calculateRebate(
        uint256 totalRebate,
        uint256[] memory relationIds
    ) external pure returns (uint256[] memory);
}
