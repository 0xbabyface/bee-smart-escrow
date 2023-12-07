// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./BeeSmartStorage.sol";

contract BeeSmart is AccessControl, BeeSmartStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Order for Order.Record;

    bytes32 public constant AdminRole     = keccak256("BeeSmart.Admin");
    bytes32 public constant CommunityRole = keccak256("BeeSmart.Community");

    event OrderMade(uint256 indexed orderId, address indexed seller, address indexed buyer, address payToken, uint256 amount);
    event OrderCancelled(uint256 indexed orderId, address indexed seller, address indexed buyer);
    event OrderAdjusted(uint256 indexed orderId, address indexed seller, address indexed buyer, uint256 preAmount, uint256 nowAmount);
    event OrderDisputed(uint256 indexed orderId, address indexed firedBy, Order.Status s);
    event OrderDisputeRecalled(uint256 indexed orderId, address indexed recalledBy);
    event OrderRecalled(uint256 indexed orderId, address indexed recalledBy);
    event OrderConfirmed(uint256 indexed orderId, uint256 buyerGotAmount, uint256 feeAmount);
    event CommunityDecided(uint256 indexed orderId, address indexed judger, uint8 decision);

    event CommunityWalletSet(address indexed admin, address indexed oldWallet, address indexed newWallet);
    event FinancialWalletSet(address indexed admin, address indexed oldWallet, address indexed newWallet);
    event CommunityFeeRatioSet(address indexed admin, uint256 ratio, uint256 buyerCharged, uint256 sellerCharged);
    event RoleSet(address indexed admin, bytes32 role, address account, bool toGrant);
    event ReputationRatioSet(address indexed admin, uint256 oldRatio, uint256 newRatio);
    event RebateRatioSet(address indexed admin, uint256 oldRatio, uint256 newRatio);
    event ExchangeRatioSet(address indexed admin, uint256 oldRatio, uint256 newRatio);

    event RelationshipSet(address indexed relationship);
    event ReputationSet(address indexed reputation);
    event RebateSet(address indexed rebate);
    event RewardFeeRatioSet(uint256 rewardForBuyer, uint256 rewardForSeller);
    event RewardClaimed(address indexed owner, uint256 amount);
    event RewardTokenSet(address indexed admin, address indexed oldTokenAddress, address indexed newTokenAddress);

    function initialize(address[] memory admins, address[] memory communities) external {
        require(initialized == 0, "already initialized");
        initialized = 1;

        for (uint i = 0; i < admins.length; ++i) {
            _grantRole(AdminRole, admins[i]);
        }

        for (uint i = 0; i < communities.length; ++i) {
            _grantRole(CommunityRole, communities[i]);
        }

        orderStatusDurationSec   = 30 * 60;  // wait seconds for new status
        communityFeeRatio        = 0.03E18;  // fee ratio: 3%
        chargesBaredBuyerRatio   = 1E18;     // 100% buyer fee ratio
        chargesBaredSellerRatio  = 0;        // 0% seller fee ratio
        rewardForBuyerRatio      = 0.7E18;  // reward for buyer
        rewardForSellerRatio     = 0.3E18;  // reward for seller
        reputationRatio          = 1E18;     // reputation points ratio:  tradeAmount * reputationRatio = Points
        rebateRatio              = 0.1E18;   // 10% of community fee will rebate to parents
        rewardExchangeRatio      = 1e18;   // 1USDT for 100CANDY rewards
    }
    // set reward token, should be decimals 18.
    function setRewardToken(address token) external onlyRole(AdminRole) {
        require(token != address(0), "token is null");
        require(token != rewardTokenAddress, "same token address");

        address oldTokenAddress = rewardTokenAddress;
        rewardTokenAddress = token;
        emit RewardTokenSet(msg.sender, oldTokenAddress, token);
    }
    // set community wallet
    function setCommunityWallet(address w) external onlyRole(AdminRole) {
        require(w != address(0), "wallet is null");
        require(w != communityWallet, "same wallet");

        address oldWallet = communityWallet;
        communityWallet = w;
        emit CommunityWalletSet(msg.sender, oldWallet, w);
    }
    // set financial wallet
    function setFinancialWallet(address fw) external onlyRole(AdminRole) {
        require(fw != address(0), "wallet is null");
        require(fw != financialWallet, "same wallet");
        address oldWallet = financialWallet;
        financialWallet = fw;
        emit CommunityWalletSet(msg.sender, oldWallet, fw);
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
        require(0 <= rewardForBuyer && rewardForBuyer <= RatioPrecision, "buyer reward ratio invalid");
        require(0 <= rewardForSeller && rewardForSeller <= RatioPrecision, "seller reward ratio invalid");
        require(rewardForBuyer + rewardForSeller == RatioPrecision, "reward ratio not percent 100");

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

    // set exchange rate for 1 usdt/usdc : x CANDY
    function setExchangeRatio(uint256 r) external onlyRole(AdminRole) {
        // require(0 <= r && r <= 1E18, "fee ratio invalid");
        uint256 oldRatio = rewardExchangeRatio;
        rewardExchangeRatio = r;
        emit ExchangeRatioSet(msg.sender, oldRatio, r);
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
    // claim CANDY rewards
    function claimRewards() external {
        uint256 relationId = relationship.getRelationId(msg.sender);
        uint256 rewardsAmount = rebateCandyRewards[relationId];
        require(rewardsAmount > 0, "no rewards claimable");

        rebateCandyRewards[relationId] = 0;
        IERC20Metadata(rewardTokenAddress).transferFrom(financialWallet, msg.sender, rewardsAmount);
        emit RewardClaimed(msg.sender, rewardsAmount);
    }
    // seller makes a order
    function makeOrder(address payToken, uint256 sellAmount, address buyer) external {
        require(supportedTokens.contains(payToken), "token not support");
        require(sellAmount > 0, "sell amount is zero");
        require(userLockedOrders[msg.sender].length() == 0, "seller has locked order");
        require(userLockedOrders[buyer].length() == 0, "buyer has locked order");

        uint256 buyerId = relationship.getRelationId(buyer);
        uint256 sellerId = relationship.getRelationId(msg.sender);
        require(sellerId != 0, "seller is not registered");
        require(buyerId != sellerId, "can not sell to self");

        uint256 alignedAmount = alignAmount18(payToken, sellAmount);
        require(reputation.isReputationEnough(buyerId, alignedAmount), "not enough reputation for buyer");
        require(reputation.isReputationEnough(sellerId, alignedAmount), "not enough reputation for seller");

        ++totalOrdersCount;

        uint256 sellerFee = sellAmount * communityFeeRatio * chargesBaredSellerRatio / RatioPrecision / RatioPrecision;
        IERC20Metadata(payToken).transferFrom(msg.sender, address(this), sellAmount + sellerFee);

        uint256 orderId = totalOrdersCount;
        orders[orderId] = Order.Record(
                                orderId,
                                sellAmount,
                                payToken,
                                uint64(block.timestamp),
                                buyer,
                                msg.sender,
                                Order.Status.NORMAL,
                                Order.Status.UNKNOWN,
                                sellerFee,
                                0,
                                uint64(block.timestamp)
        );
        sellOrdersOfUser[msg.sender].push(orderId);
        buyOrdersOfUser[buyer].push(orderId);

        emit OrderMade(orderId, msg.sender, buyer, payToken, sellAmount);
    }

    // buyer want to adjust amount of order
    function adjustOrder(uint256 orderId, uint256 targetAmount) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];

        require(order.currStatus == Order.Status.NORMAL || order.currStatus == Order.Status.ADJUSTED, "order status mismatch");
        require(order.buyer == msg.sender, "only buyer allowed");
        require(order.sellAmount > targetAmount, "amount should less than now");

        uint256 rebateFee = (order.sellAmount - targetAmount) * order.sellerFee / order.sellAmount; // rebate sell fee by ratio
        if (rebateFee > 0) order.sellerFee -= rebateFee;

        if (targetAmount == 0) {
            order.toStatus(Order.Status.CANCELLED);
            emit OrderCancelled(orderId, order.seller, order.buyer);
        } else {
            order.toStatus(Order.Status.ADJUSTED);

            uint256 preAmount = order.sellAmount;
            order.sellAmount = targetAmount;
            adjustedOrder[orderId] = Order.AdjustInfo(preAmount, targetAmount);

            emit OrderAdjusted(orderId, order.seller, order.buyer, preAmount, order.sellAmount);
        }

        IERC20Metadata(order.payToken).transfer(order.seller, (order.sellAmount - targetAmount) + rebateFee);
    }

    // seller confirmed and want to finish an order.
    function confirmOrder(uint256 orderId) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];

        require(order.seller == msg.sender, "only seller allowed");
        require(order.currStatus == Order.Status.NORMAL || order.currStatus == Order.Status.ADJUSTED, "order status mismatch");

        order.toStatus(Order.Status.CONFIRMED);

        // S1: rewards for agents, buyer, seller
        uint256 alignedAmount = alignAmount18(order.payToken, order.sellAmount);
        uint256 totalCandyRewards = alignedAmount * rewardExchangeRatio / RatioPrecision;
        uint256 rewardsForAgents  = totalCandyRewards * rebateRatio / RatioPrecision;
        rewardForAgents(order.seller, rewardsForAgents);
        rewardForBuyerAndSeller(order, totalCandyRewards -rewardsForAgents);

        // S2: charege fee for community
        uint256 communityFee = order.sellAmount * communityFeeRatio / RatioPrecision;
        uint256 buyerFee     = communityFee * chargesBaredBuyerRatio / RatioPrecision;
        uint256 buyerGotAmount = order.sellAmount - buyerFee;
        order.buyerFee = buyerFee;
        // S5: transfer token to buyer & community
        IERC20Metadata(order.payToken).transfer(order.buyer, buyerGotAmount);
        IERC20Metadata(order.payToken).transfer(communityWallet, communityFee);

        emit OrderConfirmed(orderId, buyerGotAmount, order.sellAmount - buyerGotAmount);
    }

    // seller wants to dispute
    function sellerDispute(uint256 orderId) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];
        require(order.seller == msg.sender, "only seller allowed");

        if (order.currStatus == Order.Status.NORMAL || order.currStatus == Order.Status.ADJUSTED) {
            require(order.updatedAt + orderStatusDurationSec <= block.timestamp, "status in waiting time");
            // order is in normal status, and seller raise a dispute
            order.toStatus(Order.Status.SELLERDISPUTE);
        } else if (order.currStatus == Order.Status.SELLERDISPUTE) {
            require(order.updatedAt + orderStatusDurationSec <= block.timestamp, "status in waiting time");
            // two dispute by seller, send token back to seller
            // this order is handled like being cancelled
            // no reputation nor CANDY reward is granted
            order.toStatus(Order.Status.CONFIRMED);
            releaseToSeller(order);
        } else if (order.currStatus == Order.Status.BUYERDISPUTE) {
            // both seller and buyer dispute
            // the order is locked, and should waiting for community's decision
            order.toStatus(Order.Status.LOCKED);
            lockedOrders.add(order.orderId);
            userLockedOrders[order.buyer].add(orderId);
            userLockedOrders[order.seller].add(orderId);
        } else {
            require(false, "seller can not dispute now");
        }

        emit OrderDisputed(orderId, msg.sender, order.currStatus);
    }

    // seller recall dispute
    function sellerRecallDispute(uint256 orderId) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];
        require(order.seller == msg.sender, "only seller allowed");
        require(order.currStatus == Order.Status.SELLERDISPUTE, "can not recall");

        order.toStatus(Order.Status.NORMAL);

        emit OrderDisputeRecalled(orderId, msg.sender);
    }

    // buyer wants to dispute
    function buyerDispute(uint256 orderId) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];
        require(order.buyer == msg.sender, "only buyer allowed");

        if (order.currStatus == Order.Status.NORMAL || order.currStatus == Order.Status.ADJUSTED) {
            require(order.updatedAt + orderStatusDurationSec <= block.timestamp, "status in waiting time");
            // order is in normal status, and buyer raise a dispute
            order.toStatus(Order.Status.BUYERDISPUTE);
        } else if (order.currStatus == Order.Status.BUYERDISPUTE) {
            require(order.updatedAt + orderStatusDurationSec <= block.timestamp, "status in waiting time");
            // two dispute by buyer, send token to buyer
            // charge community fee from this order,
            // but no reputation nor CANDY granted
            order.toStatus(Order.Status.CONFIRMED);
            releaseToBuyer(order);
        } else if (order.currStatus == Order.Status.SELLERDISPUTE) {
            // both seller and buyer dispute
            // the order is locked, and should waiting for community's decision
            order.toStatus(Order.Status.LOCKED);
            lockedOrders.add(order.orderId);
            userLockedOrders[order.buyer].add(orderId);
            userLockedOrders[order.seller].add(orderId);
        } else {
            require(false, "buyer can not dispute now");
        }

        emit OrderDisputed(orderId, msg.sender, order.currStatus);
    }

    // buyer recall dispute
    function buyerRecallDispute(uint256 orderId) external onlyExistOrder(orderId) {
        Order.Record storage order = orders[orderId];
        require(order.buyer == msg.sender, "only buyer allowed");
        require(order.currStatus == Order.Status.BUYERDISPUTE, "can not recall");

        order.toStatus(Order.Status.NORMAL);

       emit OrderDisputeRecalled(orderId, msg.sender);
    }

    // community decide a locked order.
    // decision should be:
    //    0: buyer win
    //    1: seller win
    //    2: no winner, set order to NORMAL status
    function communityDecide(uint256 orderId, uint8 decision)
        external
        onlyRole(CommunityRole)
        onlyExistOrder(orderId)
    {
        Order.Record storage order = orders[orderId];
        require(order.currStatus == Order.Status.LOCKED, "not locked order");
        decision = decision % 3;

        if (decision == 0 /* Buyer Win */) {
            order.toStatus(Order.Status.BUYERWIN);
            releaseToBuyer(order);
            clearReputation(order.seller);
        } else if (decision == 1 /* Seller Win*/) {
            order.toStatus(Order.Status.SELLERWIN);
            releaseToSeller(order);
            clearReputation(order.buyer);
        } else { /* set order to NORMAL */
            order.toStatus(Order.Status.NORMAL);
        }

        lockedOrders.remove(orderId);
        userLockedOrders[order.buyer].remove(orderId);
        userLockedOrders[order.seller].remove(orderId);

        emit CommunityDecided(orderId, msg.sender, decision);
    }

    //
    function getLengthOfSellOrders(address wallet) public view returns(uint256) {
        return sellOrdersOfUser[wallet].length;
    }

    function getLengthOfBuyOrders(address wallet) public view returns(uint256) {
        return buyOrdersOfUser[wallet].length;
    }

    function getSupportTokens() public view returns(address[] memory) {
        return supportedTokens.values();
    }

    function getAllLockedOrderIds() public view returns(uint256[] memory) {
        return lockedOrders.values();
    }

    function getUserLockedOrderIds(address user) public view returns(uint256[] memory) {
        return userLockedOrders[user].values();
    }

// --------------------- internal functions -------------------------------
    function releaseToBuyer(Order.Record storage order) internal {
        uint256 communityFee = order.sellAmount * communityFeeRatio / RatioPrecision;
        uint256 buyerFee     = communityFee * chargesBaredBuyerRatio / RatioPrecision;
        uint256 buyerGotAmount = order.sellAmount - buyerFee;

        order.buyerFee = buyerFee;

        IERC20Metadata(order.payToken).transfer(order.buyer, buyerGotAmount);
        IERC20Metadata(order.payToken).transfer(communityWallet, communityFee);
    }

    function releaseToSeller(Order.Record storage order) internal {
        IERC20Metadata(order.payToken).transfer(order.seller, order.sellAmount + order.sellerFee);
        order.sellerFee = 0;
    }

    function clearReputation(address dealer) internal {
        uint256 relationId = relationship.getRelationId(dealer);
        uint256 points = reputation.reputationPoints(address(this), relationId);

        reputation.takeback(relationId, points);
    }

    function rewardForAgents(address seller, uint256 fee)
        internal
        returns(uint256)
    {
        uint256 rebateAmount;
        uint256[] memory parentIds = relationship.getParentRelationId(seller, RebateLevels);
        if (parentIds.length > 0) {
            rebateAmount = fee * rebateRatio / RatioPrecision;  // 10% for rebates;
            uint256[] memory parentRebates = rebate.calculateRebate(rebateAmount, parentIds);
            for (uint256 i = 0; i < parentIds.length; ++i) {
                if (parentIds[i] == 0) break;
                rebateCandyRewards[parentIds[i]] += parentRebates[i];
            }
        }
        return rebateAmount;
    }

    function rewardForBuyerAndSeller(Order.Record memory order, uint256 candyRewards)
        internal
    {
        // S2: calculate reputation points for both seller & buyer.
        uint256 sellerRelationId = relationship.getRelationId(order.seller);
        uint256 buyerRelationId = relationship.getRelationId(order.buyer);
        uint256 alignedAmount = alignAmount18(order.payToken, order.sellAmount);
        uint256 points = alignedAmount * reputationRatio / RatioPrecision;
        reputation.grant(sellerRelationId, points);
        reputation.grant(buyerRelationId, points);
        // add 1 airdrop point for buyer and seller
        airdropPoints[sellerRelationId] += 1;
        airdropPoints[buyerRelationId] += 1;
        // S3: calculate CANDY rewards for buyer & seller
        uint256 buyerCandyReward = candyRewards * rewardForBuyerRatio / RatioPrecision;
        uint256 sellerCandyReward = candyRewards * rewardForSellerRatio / RatioPrecision;
        rebateCandyRewards[buyerRelationId] += buyerCandyReward;
        rebateCandyRewards[sellerRelationId] += sellerCandyReward;

        // S4: record rewards info
        Order.Rewards storage rewards = orderRewards[order.orderId];
        rewards.buyerRewards = uint128(buyerCandyReward);
        rewards.sellerRewards = uint128(sellerCandyReward);
        rewards.buyerReputation = uint128(points);
        rewards.sellerReputation = uint128(points);
        rewards.buyerAirdropPoints = uint128(1);
        rewards.sellerAirdropPoints = uint128(1);
    }
}
