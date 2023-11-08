// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./BeeSmartStorage.sol";

contract BeeSmart is AccessControl, BeeSmartStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant AdminRole     = keccak256("BeeSmart.Admin");
    bytes32 public constant CommunityRole = keccak256("BeeSmart.Community");

    event OrderMade(uint256 indexed orderId, address indexed seller, address indexed buyer, address payToken, uint256 amount);
    event OrderCancelled(uint256 indexed orderId, address indexed seller, address indexed buyer);
    event OrderAdjusted(uint256 indexed orderId, address indexed seller, address indexed buyer, uint256 preAmount, uint256 nowAmount);
    event OrderDisputed(uint256 indexed orderId, address indexed firedBy);
    event OrderDisputeRecalled(uint256 indexed orderId, address indexed recalledBy);
    event OrderRecalled(uint256 indexed orderId, address indexed recalledBy);
    event OrderConfirmed(uint256 indexed orderId, uint256 buyerGotAmount, uint256 feeAmount);

    event CommunityWalletSet(address indexed admin, address indexed oldWallet, address indexed newWallet);
    event CommunityFeeRatioSet(address indexed admin, uint256 ratio, uint256 buyerCharged, uint256 sellerCharged);
    event RoleSet(address indexed admin, bytes32 role, address account, bool toGrant);
    event ReputationRatioSet(address indexed admin, uint256 oldRatio, uint256 newRatio);
    event RebateRatioSet(address indexed admin, uint256 oldRatio, uint256 newRatio);

    event RelationshipSet(address indexed relationship);
    event ReputationSet(address indexed reputation);
    event RebateSet(address indexed rebate);
    event RewardFeeRatioSet(uint256 rewardForBuyer, uint256 rewardForSeller);

    function initialize(address[] memory admins, address[] memory communities) external {
        require(initialized == 0, "only once");
        initialized = 1;

        for (uint i = 0; i < admins.length; ++i) {
            _grantRole(AdminRole, admins[i]);
        }

        for (uint i = 0; i < communities.length; ++i) {
            _grantRole(CommunityRole, communities[i]);
        }
    }
    // set community wallet
    function setCommunityWallet(address w) external onlyRole(AdminRole) {
        require(w != address(0), "wallet is null");
        require(w != communityWallet, "same wallet");

        address oldWallet = communityWallet;
        communityWallet = w;
        emit CommunityWalletSet(msg.sender, oldWallet, w);
    }
    // set community fee ratio
    function setCommunityFeeRatio(uint256 r, uint256 buyerChargedRatio, uint256 sellerChargedRatio) external onlyRole(AdminRole) {
        require(0 <= r && r <= 1E18, "fee ratio invalid");
        require(buyerChargedRatio + sellerChargedRatio == RatioPrecision, "buyer and seller charged not percent 100");

        communityFeeRatio = r;
        chargesBaredBuyerRatio = buyerChargedRatio;
        chargesBaredSellerRatio = sellerChargedRatio;

        emit CommunityFeeRatioSet(msg.sender, r, buyerChargedRatio, sellerChargedRatio);
    }

    // set reward fee ratio for buyer & seller
    function setRewardFeeRatio(uint256 rewardForBuyer, uint256 rewardForSeller) external onlyRole(AdminRole) {
        require(0 <= rewardForBuyer && rewardForBuyer <= 1E18, "buyer reward ratio invalid");
        require(0 <= rewardForSeller && rewardForSeller <= 1E18, "seller reward ratio invalid");

        rewardForBuyerRatio = rewardForBuyer;
        rewardForSellerRatio = rewardForSeller;

        emit RewardFeeRatioSet(rewardForBuyer, rewardForSeller);
    }
    // set role
    function setRole(bytes32 role, address account, bool toGrant) external onlyRole(AdminRole) {
        require(role == AdminRole || role == CommunityRole, "unknown role");
        require(account != address(0), "grant to null address");

        if (toGrant) _grantRole(role, account);
        else _revokeRole(role, account);

        emit RoleSet(msg.sender, role, account, toGrant);
    }

    // set reputation ratio
    function setReputationRatio(uint256 r) external onlyRole(AdminRole) {
        require(0 <= r && r <= 1E18, "fee ratio invalid");
        uint256 oldRatio = reputationRatio;
        reputationRatio = r;
        emit ReputationRatioSet(msg.sender, oldRatio, r);
    }
    // set rebate fee ratio for upper argents
    function setRebateRatio(uint256 r) external onlyRole(AdminRole) {
        require(0 <= r && r <= 1E18, "fee ratio invalid");
        uint256 oldRatio = rebateRatio;
        rebateRatio = r;
        emit RebateRatioSet(msg.sender, oldRatio, r);
    }
    // add tradable tokens
    function addSupportTokens(address[] memory tokens) external onlyRole(AdminRole) {
        for (uint i = 0; i < tokens.length; ++i) {
            if (supportedTokens.contains(tokens[i])) continue;
            else {
                supportedTokens.add(tokens[i]);
                supportedTokenDecimals[tokens[i]] = IERC20Metadata(tokens[i]).decimals();
            }
        }
    }

    // remove tradable tokens
    function removeSupportTokens(address[] memory tokens) external onlyRole(AdminRole) {
        for (uint i = 0; i < tokens.length; ++i) {
            if (supportedTokens.contains(tokens[i])) supportedTokens.remove(tokens[i]);
        }
    }

    function setRelationship(IRelationship rs) external onlyRole(AdminRole) {
        require(address(rs).code.length > 0, "invalid relaionship contract");
        relationship = rs;
        emit RelationshipSet(address(rs));
    }

    function setReputation(IReputation rep) external onlyRole(AdminRole) {
        require(address(rep).code.length > 0, "invalid reputaion contract");
        reputation = rep;
        emit ReputationSet(address(rep));
    }

    function setRebate(IRebate reb) external onlyRole(AdminRole) {
        require(address(reb).code.length > 0, "invalid rebate contract");
        rebate = reb;
        emit RebateSet(address(reb));
    }

    function setOrderStatusDurationSec(uint64 sec) external onlyRole(AdminRole) {
        orderStatusDurationSec = sec;
    }

    function alignAmount18(address payToken, uint256 sellAmount) internal view returns(uint256) {
        return sellAmount * 10**(18 - supportedTokenDecimals[payToken]);
    }
    // seller makes a order
    function makeOrder(address payToken, uint256 sellAmount, address buyer) external {
        require(supportedTokens.contains(payToken), "token not support");
        require(sellAmount > 0, "pay amount zero");

        uint256 buyerId = relationship.getRelationId(buyer);
        uint256 sellerId = relationship.getRelationId(msg.sender);
        require(buyerId != sellerId, "can not sell to self");

        uint256 alignedAmount = alignAmount18(payToken, sellAmount);
        require(reputation.isReputationEnough(buyerId, alignedAmount), "not enough reputation for buyer");
        require(reputation.isReputationEnough(sellerId, alignedAmount), "not enough reputation for seller");

        ++totalOrdersCount;

        uint256 orderId = totalOrdersCount;

        orders[orderId] = Order(orderId, payToken, sellAmount, buyer, msg.sender, OrderStatus.WAITING, uint64(block.timestamp));
        sellOrdersOfUser[msg.sender].push(orderId);
        buyOrdersOfUser[buyer].push(orderId);

        uint256 sellerFee = sellAmount * communityFeeRatio * chargesBaredSellerRatio / RatioPrecision / RatioPrecision;

        IERC20Metadata(payToken).transferFrom(msg.sender, address(this), sellAmount + sellerFee);

        emit OrderMade(orderId, msg.sender, buyer, payToken, sellAmount);
    }

    // buyer want to adjust amount of order
    function adjustOrder(uint256 orderId, uint256 amount) external {
        Order storage order = orders[orderId];

        require(order.status == OrderStatus.WAITING || order.status == OrderStatus.ADJUSTED, "order status mismatch");
        require(order.buyer == msg.sender, "only buyer allowed");
        require(order.sellAmount >= amount, "amount overflow");

        if (order.sellAmount == amount) {
            order.status = OrderStatus.CANCELLED;
            emit OrderCancelled(orderId, order.seller, order.buyer);
        } else {
            uint256 preAmount = order.sellAmount;
            order.sellAmount -= amount;
            order.status = OrderStatus.ADJUSTED;

            adjustedOrder[orderId] = AdjustInfo(preAmount, order.sellAmount);

            emit OrderAdjusted(orderId, order.seller, order.buyer, preAmount, order.sellAmount);
        }

        order.updatedAt = uint64(block.timestamp);

        // FIXME: (not charge fee when makeOrder, but should return back while adjustOrder)
        uint256 sellerFee = amount * communityFeeRatio * chargesBaredSellerRatio / RatioPrecision / RatioPrecision;

        IERC20Metadata(order.payToken).transfer(order.seller, amount + sellerFee);
    }

    // seller confirmed and want to finish an order.
    function confirmOrder(uint256 orderId) external {
        Order storage order = orders[orderId];

        require(order.status == OrderStatus.WAITING || order.status == OrderStatus.ADJUSTED, "order status mismatch");
        require(order.seller == msg.sender, "only seller allowed");

        order.status = OrderStatus.CONFIRMED;
        order.updatedAt = uint64(block.timestamp);

        // S1: calculate fees for community & upper parents with CANDY
        uint256 communityFee = order.sellAmount * communityFeeRatio / RatioPrecision;
        // uint256 sellerFee    = communityFee * chargesBaredSellerRatio / RatioPrecision;
        uint256 buyerFee     = communityFee * chargesBaredBuyerRatio / RatioPrecision;

        uint256 buyerGotAmount = order.sellAmount - buyerFee;

        uint256[] memory parentIds = relationship.getParentRelationId(order.seller, RebateLevels);
        if (parentIds.length > 0) {
            uint256 rebateAmount = communityFee * rebateRatio / RatioPrecision;  // 10% for rebates;
            uint256[] memory parentRebates = rebate.calculateRebate(rebateAmount, parentIds);
            for (uint256 i = 0; i < parentIds.length; ++i) {
                if (parentIds[i] == 0) break;
                rebateRewards[parentIds[i]] += parentRebates[i];
            }

            communityFee -= rebateAmount;
        }

        // S2: calculate reputation points for both seller & buyer.
        uint256 sellerRelationId = relationship.getRelationId(order.seller);
        uint256 buyerRelationId = relationship.getRelationId(order.buyer);

        uint256 alignedAmount = alignAmount18(order.payToken, order.sellAmount);
        uint256 points = alignedAmount * reputationRatio / RatioPrecision;

        reputation.grant(sellerRelationId, points);
        reputation.grant(buyerRelationId, points);

        airdropPoints[sellerRelationId] += 1;
        airdropPoints[buyerRelationId] += 1;

        // S3: calculate CANDY rewards for buyer & seller
        uint256 buyerCandyReward = order.sellAmount * rewardForBuyerRatio / RatioPrecision;
        uint256 sellerCandyReward = order.sellAmount * rewardForSellerRatio / RatioPrecision;
        rebateRewards[buyerCandyReward] += buyerCandyReward;
        rebateRewards[sellerRelationId] += sellerCandyReward;

        // S4: record rewards info
        OrderRewards storage rewards = orderRewards[orderId];
        rewards.buyerRewards = uint128(buyerCandyReward);
        rewards.sellerRewards = uint128(sellerCandyReward);
        rewards.buyerReputation = uint128(points);
        rewards.sellerReputation = uint128(points);
        rewards.buyerAirdropPoints = uint128(1);
        rewards.sellerAirdropPoints = uint128(1);

        // S5: transfer token to buyer & community
        IERC20Metadata(order.payToken).transfer(order.buyer, buyerGotAmount);
        IERC20Metadata(order.payToken).transfer(communityWallet, communityFee);

        emit OrderConfirmed(orderId, buyerGotAmount, order.sellAmount - buyerGotAmount);
    }

    // buyer or seller wants to dispute
    function dispute(uint256 orderId) external {
        Order storage order = orders[orderId];
        require(order.updatedAt + orderStatusDurationSec <= block.timestamp, "in waiting time");
        require(order.status == OrderStatus.WAITING || order.status == OrderStatus.ADJUSTED, "order status mismatch");
        require(order.buyer == msg.sender || order.seller == msg.sender, "only buyer or seller allowed");

        order.status = OrderStatus.DISPUTING;
        order.updatedAt = uint64(block.timestamp);

        disputedOrder[orderId] = DisputeInfo(msg.sender);

        emit OrderDisputed(orderId, msg.sender);
    }

    // buyer or seller or community role can recall a dispution.
    function recallDispute(uint256 orderId) external {
        Order storage order = orders[orderId];

        require(order.status == OrderStatus.DISPUTING, "order status mismatch");
        require(disputedOrder[orderId].originator == msg.sender || hasRole(CommunityRole, msg.sender), "not allowd");

        order.status = OrderStatus.WAITING;
        order.updatedAt = uint64(block.timestamp);

        delete disputedOrder[orderId];

        emit OrderDisputeRecalled(orderId, msg.sender);
    }

    // some disputes happend and community make the recall decision.
    function recallOrder(uint256 orderId, address winner) external onlyRole(CommunityRole) {
        Order storage order = orders[orderId];

        require(order.status == OrderStatus.DISPUTING, "order status mismatch");

        order.status = OrderStatus.RECALLED;
        order.updatedAt = uint64(block.timestamp);

        delete disputedOrder[orderId];

        // minus the reputation points from order.disputeOriginator
        uint256 points = order.sellAmount * reputationRatio / RatioPrecision;
        if (winner == order.seller) {
            reputation.takeback(relationship.getRelationId(order.buyer), points);
        } else if (winner == order.buyer) {
            reputation.takeback(relationship.getRelationId(order.seller), points);
        }

        // FIXME: (not charge fee when makeOrder, but should return back while adjustOrder)
        uint256 sellerFee = order.sellAmount * communityFeeRatio * chargesBaredSellerRatio / RatioPrecision / RatioPrecision;
        IERC20Metadata(order.payToken).transfer(order.seller, order.sellAmount + sellerFee);

        emit OrderRecalled(orderId, msg.sender);
    }

    //
    function getLengthOfSellOrders(address wallet) public view returns(uint256) {
        return sellOrdersOfUser[wallet].length;
    }

    function getLengthOfBuyOrders(address wallet) public view returns(uint256) {
        return buyOrdersOfUser[wallet].length;
    }

    function getSupportTokens() public view returns(address[] memory) {
        uint length = supportedTokens.length();
        address[] memory tokens = new address[](length);
        for (uint i = 0; i < length; ++i) {
            tokens[i] = supportedTokens.at(i);
        }
        return tokens;
    }
}
