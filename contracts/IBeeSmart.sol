// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./components/IReputation.sol";
import "./components/AgentManager.sol";
import "./libs/Order.sol";

interface IBeeSmart {
    function getLengthOfSellOrders(address) external view returns(uint256);
    function getLengthOfBuyOrders(address) external view returns(uint256);
    function sellOrdersOfUser(address, uint256) external view returns(uint256);
    function buyOrdersOfUser(address, uint256) external view returns(uint256);
    function orders(uint256) external view returns(Order.Record memory);
    function orderRewards(uint256) external view returns(Order.Rewards memory);
    function reputation() external view returns(IReputation);
    function airdropPoints(address) external view returns(uint256);
    function getSupportTokens() external view returns(address[] memory);
    function getAllLockedOrderIds() external view returns(uint256[] memory);
    function getUserLockedOrderIds(address user) external view returns(uint256[] memory);
    function boundAgents(address user) external view returns(uint96);
    function agentMgr() external view returns(AgentManager);
    function communityWallet() external view returns(address);
    function operatorWallet() external view returns(address);
    function globalShareWallet() external view returns(address);
    function orderStatusDurationSec() external view returns(uint64);
    function communityFeeRatio() external view returns(uint256);
    function operatorFeeRatio() external view returns(uint256);
    function globalShareFeeRatio() external view returns(uint256);
    function sameLevelFeeRatio() external view returns(uint256);
    function chargesBaredBuyerRatio() external view returns(uint256);
    function chargesBaredSellerRatio() external view returns(uint256);
    function reputationRatio() external view returns(uint256);
    function disputeWinnerFeeRatio() external view returns(uint256);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function AdminRole() external view returns(bytes32);
    function CommunityRole() external view returns(bytes32);
    function pendingRewards(address owner, address payToken) external view returns(uint256);
}
