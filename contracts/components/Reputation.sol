// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Reputation {

    uint96  public constant RelationStartIndex = 200000000;
    uint256 public constant InitReputationPoints = 5000e18;
    // holder => amount
    mapping(address => uint256) public reputationPoints;

    address public beeSmart;
    uint96  public totalRelations;

    event ReputationGranted(address indexed holder, uint256 amount);
    event ReputationTookback(address indexed holder, uint256 amount);

    modifier onlyBeeSmart() {
        require(msg.sender == beeSmart, "Reputation: only beesmart");
        _;
    }

    constructor(address smart) {
        beeSmart = smart;
    }

    function name() external pure returns(string memory) {
        return "Bee Smart Repulation Points";
    }

    function symbol() external pure returns(string memory) {
        return "BSRP";
    }

    function onRelationBound(address holder) external onlyBeeSmart returns(uint96) {
        reputationPoints[holder] = InitReputationPoints;
        ++totalRelations;
        return (RelationStartIndex + totalRelations);
    }

    function grant(address holder, uint256 amount) external onlyBeeSmart() {
        reputationPoints[holder] += amount;
        emit ReputationGranted(holder, amount);
    }

    function takeback(address holder, uint256 amount) external onlyBeeSmart {
        if (reputationPoints[holder] >= amount ) {
            reputationPoints[holder] -= amount;
        } else {
            reputationPoints[holder] = 0;
        }

        emit ReputationTookback(holder, amount);
    }

    function isReputationEnough(address holder, uint256 amount) external view returns(bool) {
        return reputationPoints[holder] >= amount;
    }
}
