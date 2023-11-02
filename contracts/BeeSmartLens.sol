// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./components/IRelationship.sol";
import "./components/IReputation.sol";

enum OrderStatus { UNKNOWN, WAITING, ADJUSTED, CONFIRMED, CANCELLED, DISPUTING, RECALLED }
struct Order {
    uint256 orderId;
    address payToken;
    uint256 sellAmount;
    address buyer;
    address seller;
    OrderStatus status;
    uint64  updatedAt;
}

struct OrderRewards {
    uint128 buyerRewards;
    uint128 sellerRewards;
    uint128 buyerAirdropPoints;
    uint128 sellerAirdropPoints;
    uint128 buyerReputation;
    uint128 sellerReputation;
}

interface IBeeSmart {
    function getLengthOfSellOrders(address) external view returns(uint256);
    function getLengthOfBuyOrders(address) external view returns(uint256);
    function sellOrdersOfUser(address, uint256) external view returns(uint256);
    function buyOrdersOfUser(address, uint256) external view returns(uint256);
    function orders(uint256) external view returns(Order memory);
    function orderRewards(uint256) external view returns(OrderRewards memory);
    function relationship() external view returns(IRelationship);
    function reputation() external view returns(IReputation);
    function airdropPoints(uint256) external view returns(uint256);
    function getSupportTokens() external view returns(address[] memory);
    function rebateRewards(uint256) external view returns(uint256);
}

contract BeeSmartLens {
    function getOngoingSellOrders(IBeeSmart smart, address wallet, uint256 timestamp, uint256 maxCount) public view returns(Order[] memory) {
        uint256 length = smart.getLengthOfSellOrders(wallet);

        uint256[] memory hashes = new uint256[](length);
        uint count;
        for (uint i = length; i >= 1; --i) {
            uint256 orderId =  smart.sellOrdersOfUser(wallet, i - 1);
            Order memory ord = smart.orders(orderId);
            if (ord.updatedAt <= timestamp &&
                (ord.status == OrderStatus.WAITING || ord.status == OrderStatus.ADJUSTED || ord.status == OrderStatus.DISPUTING)
            ) {
                hashes[count] = orderId;
                ++count;
            }
        }

        uint256 resultCount = maxCount > count ? count : maxCount;
        Order[] memory resultOrders = new Order[](resultCount);
        for (uint i = 0; i < resultCount; ++i) {
            resultOrders[i] = smart.orders(hashes[count - i - 1]);
        }
        return resultOrders;
    }

    function getOngoingBuyOrders(IBeeSmart smart, address wallet, uint256 timestamp, uint256 maxCount) public view returns(Order[] memory) {
        uint256 length = smart.getLengthOfBuyOrders(wallet);
        uint256[] memory hashes = new uint256[](length);
        uint count;
        for (uint i = length; i >= 1; --i) {
            uint256 orderId =  smart.buyOrdersOfUser(wallet, i - 1);
            Order memory ord = smart.orders(orderId);
            if (ord.updatedAt <= timestamp &&
                (ord.status == OrderStatus.WAITING || ord.status == OrderStatus.ADJUSTED || ord.status == OrderStatus.DISPUTING)
            ) {
                hashes[count] = orderId;
                ++count;
            }
        }

        uint256 resultCount = maxCount > count ? count : maxCount;
        Order[] memory resultOrders = new Order[](resultCount);
        for (uint i = 0; i < resultCount; ++i) {
            resultOrders[i] = smart.orders(hashes[count - i - 1]);
        }
        return resultOrders;
    }

    function getHistorySellOrders(IBeeSmart smart, address wallet, uint256 timestamp, uint256 maxCount)
        public
        view
        returns(Order[] memory, OrderRewards[] memory)
    {
        uint256 length = smart.getLengthOfSellOrders(wallet);
        uint256[] memory hashes = new uint256[](length);

        uint count;
        for (uint i = length; i >= 1; --i) {
            uint256 orderId =  smart.sellOrdersOfUser(wallet, i - 1);
            Order memory ord = smart.orders(orderId);
            if (ord.updatedAt <= timestamp &&
                (ord.status == OrderStatus.CONFIRMED || ord.status == OrderStatus.CANCELLED || ord.status == OrderStatus.RECALLED)
            ) {
                hashes[count] = orderId;
                ++count;
            }
        }

        uint256 resultCount = maxCount > count ? count : maxCount;
        Order[] memory resultOrders = new Order[](resultCount);
        OrderRewards[] memory historyOrdersRewards = new OrderRewards[](resultCount);
        for (uint i = 0; i < resultCount; ++i) {
            resultOrders[i] = smart.orders(hashes[count - i - 1]);
            historyOrdersRewards[i] = smart.orderRewards(hashes[count - i - 1]);
        }
        return (resultOrders, historyOrdersRewards);
    }

    function getHistoryBuyOrders(IBeeSmart smart, address wallet, uint256 timestamp, uint256 maxCount)
        public
        view
        returns(Order[] memory, OrderRewards[] memory)
    {
        uint256 length = smart.getLengthOfBuyOrders(wallet);
        uint256[] memory hashes = new uint256[](length);

        uint count;
        for (uint i = length; i >= 1; --i) {
            uint256 orderId =  smart.buyOrdersOfUser(wallet, i - 1);
            Order memory ord = smart.orders(orderId);
            if (ord.updatedAt <= timestamp &&
                (ord.status == OrderStatus.CONFIRMED || ord.status == OrderStatus.CANCELLED || ord.status == OrderStatus.RECALLED)
            ) {
                hashes[count] = orderId;
                ++count;
            }
        }

        uint256 resultCount = maxCount > count ? count : maxCount;
        Order[] memory resultOrders = new Order[](resultCount);
        OrderRewards[] memory historyOrdersRewards = new OrderRewards[](resultCount);
        for (uint i = 0; i < resultCount; ++i) {
            resultOrders[i] = smart.orders(hashes[count - i - 1]);
            historyOrdersRewards[i] = smart.orderRewards(hashes[count - i - 1]);
        }
        return (resultOrders, historyOrdersRewards);
    }

    function getTotalSellOrders(IBeeSmart smart, address wallet, uint256 startIndex, uint256 itemCount) public view returns(Order[] memory) {
        uint256 length = smart.getLengthOfSellOrders(wallet);
        uint256 count = length >= (startIndex + itemCount) ? itemCount : (length - startIndex);
        Order[] memory orders = new Order[](count);

        uint256 j = 0;
        for (uint i = startIndex; i < startIndex + count; ++i) {
            uint256 orderId =  smart.sellOrdersOfUser(wallet, i);
            orders[j]  = smart.orders(orderId);
            ++j;
        }

        return orders;
    }

    function getTotalBuyOrders(IBeeSmart smart, address wallet, uint256 startIndex, uint256 itemCount) public view returns(Order[] memory) {
        uint256 length = smart.getLengthOfBuyOrders(wallet);
        uint256 count = length >= (startIndex + itemCount) ? itemCount : (length - startIndex);
        Order[] memory orders = new Order[](count);

        uint256 j = 0;
        for (uint i = startIndex; i < startIndex + count; ++i) {
            uint256 orderId =  smart.buyOrdersOfUser(wallet, i);
            orders[j]  = smart.orders(orderId);
            ++j;
        }

        return orders;
    }

    // read both buyer & seller order of this wallet, less than 200 orders.
    function getStatusUpdatedSellOrder(
        IBeeSmart smart,
        address wallet,
        uint256 itemCount,
        uint256 updatedAfter
    ) public view returns(Order[] memory) {
        uint256 length = smart.getLengthOfSellOrders(wallet);
        Order[] memory tempOrders = new Order[](length);

        uint256 j;
        for (uint256 i = length; i>= 1; --i) {
            uint256 orderId =  smart.sellOrdersOfUser(wallet, i - 1);
            Order memory ord = smart.orders(orderId);
            if (ord.updatedAt > updatedAfter) {
                tempOrders[j] = ord;
                ++j;
            }
        }

        uint resultCount = itemCount > j ? j : itemCount;
        Order[] memory resultOrders = new Order[](resultCount);
        for (uint i = 0; i < resultCount; ++i) {
            resultOrders[i] = tempOrders[i];
        }

        return resultOrders;
    }

    function getStatusUpdatedBuyOrder(
        IBeeSmart smart,
        address wallet,
        uint256 itemCount,
        uint256 updatedAfter
    ) public view returns(Order[] memory) {
        uint256 length = smart.getLengthOfBuyOrders(wallet);
        Order[] memory tempOrders = new Order[](length);

        uint256 j;
        for (uint256 i = length; i>= 1; --i) {
            uint256 orderId =  smart.buyOrdersOfUser(wallet, i - 1);
            Order memory ord = smart.orders(orderId);
            if (ord.updatedAt > updatedAfter) {
                tempOrders[j] = ord;
                ++j;
            }
        }

        uint resultCount = itemCount > j ? j : itemCount;
        Order[] memory resultOrders = new Order[](resultCount);
        for (uint i = 0; i < resultCount; ++i) {
            resultOrders[i] = tempOrders[i];
        }

        return resultOrders;
    }

    struct AssetBalance {
        address token;
        string symbol;
        uint8  decimals;
        uint256 balance;
    }

    struct UserInfo {
        uint256 relationId;
        uint256 airdropCount;
        uint256 reputationCount;
        uint256 totalTrades;
        uint256 rebateAmount; // rebate token is Candy.
        AssetBalance[] assetsBalance;
    }

    function getUserInfo(IBeeSmart smart, address wallet) public view returns(UserInfo memory) {
        IRelationship relationship = smart.relationship();
        IReputation reputation = smart.reputation();

        uint256 relationId = relationship.getRelationId(wallet);
        address[] memory tradableTokens = smart.getSupportTokens();

        UserInfo memory info = UserInfo({
            relationId: relationId,
            airdropCount: smart.airdropPoints(relationId),
            reputationCount: reputation.reputationPoints(address(smart), relationId),
            totalTrades: smart.getLengthOfBuyOrders(wallet) + smart.getLengthOfSellOrders(wallet),
            rebateAmount: 0,
            assetsBalance: new AssetBalance[](tradableTokens.length)
        });

        info.rebateAmount = smart.rebateRewards(relationId);

        for (uint i = 0; i < tradableTokens.length; ++i) {
            address token = tradableTokens[i];
            IERC20Metadata erc20 = IERC20Metadata(token);
            info.assetsBalance[i] = AssetBalance(tradableTokens[i], erc20.symbol(), erc20.decimals(), erc20.balanceOf(wallet));
        }

        return info;
    }
}