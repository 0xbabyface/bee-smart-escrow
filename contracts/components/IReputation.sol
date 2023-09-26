// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IReputation {

    function reputationPoints(address issuer, uint256 relationId) external view returns(uint256);

    function grant(uint256 relationId, uint256 amount) external;

    function takeback(uint256 relationId, uint256 amount) external;
}
