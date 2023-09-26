// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Reputation {
    // issuer => relationId => amount
    mapping(address => mapping(uint256 => uint256)) reputationPoints;

    event ReputationGranted(address indexed issuer, uint256 indexed relationId, uint256 amount);
    event ReputationTookback(address indexed issuer, uint256 indexed relationId, uint256 amount);

    constructor() {}

    function name() external pure returns(string memory) {
        return "Bee Smart Repulation Points";
    }

    function symbol() external pure returns(string memory) {
        return "BSRP";
    }

    function grant(uint256 relationId, uint256 amount) external {
        reputationPoints[msg.sender][relationId] += amount;
        emit ReputationGranted(msg.sender, relationId, amount);
    }

    function takeback(uint256 relationId, uint256 amount) external {
        if (reputationPoints[msg.sender][relationId] >= amount ) {
            reputationPoints[msg.sender][relationId] -= amount;
        } else {
            reputationPoints[msg.sender][relationId] = 0;
        }

        emit ReputationTookback(msg.sender, relationId, amount);
    }
}
