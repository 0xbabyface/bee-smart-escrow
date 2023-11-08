// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Reputation {

    uint256 public constant InitReputationPoints = 500e18;
    // issuer => relationId => amount
    mapping(address => mapping(uint256 => uint256)) _reputationPoints;
    // issuer => relationId => bool
    mapping(address => mapping(uint256 => bool)) public relationInitialized;

    event ReputationGranted(address indexed issuer, uint256 indexed relationId, uint256 amount);
    event ReputationTookback(address indexed issuer, uint256 indexed relationId, uint256 amount);

    constructor() {}

    function name() external pure returns(string memory) {
        return "Bee Smart Repulation Points";
    }

    function symbol() external pure returns(string memory) {
        return "BSRP";
    }

    function reputationPoints(address issuer, uint256 relationId) external view returns(uint256) {
        return relationInitialized[issuer][relationId]
               ? _reputationPoints[issuer][relationId]
               : InitReputationPoints;
    }

    function isReputationEnough(uint256 relationId, uint256 amount) external returns(bool) {
        if (!relationInitialized[msg.sender][relationId]) {
            relationInitialized[msg.sender][relationId] = true;
            _reputationPoints[msg.sender][relationId] = InitReputationPoints;
        }

        return _reputationPoints[msg.sender][relationId] >= amount;
    }

    function grant(uint256 relationId, uint256 amount) external {
        _reputationPoints[msg.sender][relationId] += amount;
        emit ReputationGranted(msg.sender, relationId, amount);
    }

    function takeback(uint256 relationId, uint256 amount) external {
        if (_reputationPoints[msg.sender][relationId] >= amount ) {
            _reputationPoints[msg.sender][relationId] -= amount;
        } else {
            _reputationPoints[msg.sender][relationId] = 0;
        }

        emit ReputationTookback(msg.sender, relationId, amount);
    }
}
