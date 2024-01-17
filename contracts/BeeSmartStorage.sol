// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./components/IRelationship.sol";
import "./components/IReputation.sol";
import "./libs/Order.sol";
import "./components/AgentManager.sol";

contract BeeSmartStorage {

    modifier onlyExistOrder(uint256 id) {
        require(orders[id].updatedAt != 0, "order not exist");
        _;
    }

    uint256 public constant RatioPrecision = 1E18;
    uint8   public initialized = 1;
    uint256 public totalOrdersCount;

    EnumerableSet.AddressSet supportedTokens; // supported ERC20.
    // token address => decimals
    mapping(address => uint256) supportedTokenDecimals;

    mapping(uint256 => Order.Record) public orders; // total orders, includes pendings and finished orders.

    // orderId => AdjustInfo
    mapping(uint256 => Order.AdjustInfo) public adjustedOrder;
    // orderId => OrderRewards
    mapping(uint256 => Order.Rewards) public orderRewards;

    mapping(address => uint256[]) public sellOrdersOfUser;
    mapping(address => uint256[]) public buyOrdersOfUser;

    // trader => airdrop points
    mapping(address => uint256) public airdropPoints;

    IRelationship public relationship;
    IReputation   public reputation;
    AgentManager  public agentMgr;

    address       public communityWallet;

    uint64        public orderStatusDurationSec = 30 * 60; // 30 minutes waiting for order status
    uint256       public communityFeeRatio = 0.03E18;  // fee ratio: 0.3%
    uint256       public chargesBaredBuyerRatio = 1E18;  // 100% buyer fee ratio
    uint256       public chargesBaredSellerRatio = 0;  // 0% seller fee ratio
    uint256       public reputationRatio = 1E18; // reputation points ratio:  tradeAmount * reputationRatio = Points

    EnumerableSet.UintSet lockedOrders;  // all locked orders
    mapping(address => EnumerableSet.UintSet) userLockedOrders;
}