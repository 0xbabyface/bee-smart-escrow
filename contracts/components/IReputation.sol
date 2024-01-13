// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IReputation {
    function isReputationEnough(address holder, uint256 amount) external view returns(bool);

    function reputationPoints(address holder) external view returns(uint256);

    function grant(address holder, uint256 amount) external;

    function takeback(address holder, uint256 amount) external;

    function onRelationBound(address holder) external;
}
