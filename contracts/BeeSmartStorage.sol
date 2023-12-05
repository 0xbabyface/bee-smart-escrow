// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./components/IRelationship.sol";
import "./components/IReputation.sol";
import "./components/IRebate.sol";
import "./libs/Order.sol";

contract BeeSmartStorage {

    modifier onlyExistOrder(uint256 id) {
        require(orders[id].updatedAt != 0, "order not exist");
        _;
    }

    uint256 public constant RatioPrecision = 1E18;
    uint256 public constant RebateLevels = 10;

    uint256 public totalOrdersCount;

    EnumerableSet.AddressSet supportedTokens; // supported ERC20.
    // token address => decimals
    mapping(address => uint256) supportedTokenDecimals;

    mapping(uint256 => Order.Record) public orders; // total orders, includes pendings and finished orders.
    // orderId => DisputeInfo
    // mapping(uint256 => StatusTransform) public statusTransform;
    // orderId => AdjustInfo
    mapping(uint256 => Order.AdjustInfo) public adjustedOrder;
    // orderId => OrderRewards
    mapping(uint256 => Order.Rewards) public orderRewards;

    mapping(address => uint256[]) public sellOrdersOfUser;
    mapping(address => uint256[]) public buyOrdersOfUser;

    // relationId => rebate (for CANDY)
    mapping(uint256 => uint256) public rebateCandyRewards;
    // relationId => airdrop points
    mapping(uint256 => uint256) public airdropPoints;

    uint8         public initialized = 1;

    IRelationship public relationship;
    IReputation   public reputation;
    IRebate       public rebate;

    address       public rewardTokenAddress;
    address       public communityWallet;
    address       public financialWallet;

    uint64        public orderStatusDurationSec = 30 * 60; // 30 minutes waiting for order status
    uint256       public communityFeeRatio = 0.03E18;  // fee ratio: 0.3%
    uint256       public chargesBaredBuyerRatio = 1E18;  // 100% buyer fee ratio
    uint256       public chargesBaredSellerRatio = 0;  // 0% seller fee ratio
    uint256       public rewardForBuyerRatio = 0.03E18;  // reward for buyer
    uint256       public rewardForSellerRatio = 0.03E18;  // reward for seller
    uint256       public reputationRatio = 1E18; // reputation points ratio:  tradeAmount * reputationRatio = Points
    uint256       public rebateRatio = 0.1E18;  // 10% of community fee will rebate to parents
    uint256       public rewardExchangeRatio = 100e18;  // exchange ratio for 1 USDT = 100 CANDY as default

    EnumerableSet.UintSet lockedOrders;  // all locked orders
    mapping(address => EnumerableSet.UintSet) userLockedOrders;
}