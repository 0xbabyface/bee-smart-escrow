// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./components/IRelationship.sol";
import "./components/IReputation.sol";

enum OrderStatus { UNKNOWN, WAITING, ADJUSTED, CONFIRMED, CANCELLED, TIMEOUT, DISPUTING, RECALLED }
struct Order {
    bytes32 orderHash;
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
    uint64 buyerAirdropPoints;
    uint64 sellerAirdropPoints;
    uint64 buyerReputation;
    uint64 sellerReputation;
}

interface IBeeSmart {
    function getLengthOfSellOrders(address) external view returns(uint256);
    function getLengthOfBuyOrders(address) external view returns(uint256);
    function sellOrdersOfUser(address, uint256) external view returns(bytes32);
    function buyOrdersOfUser(address, uint256) external view returns(bytes32);
    function orders(bytes32) external view returns(Order memory);
    function orderRewards(bytes32) external view returns(OrderRewards memory);
    function relationship() external view returns(IRelationship);
    function reputation() external view returns(IReputation);
    function airdropPoints(uint256) external view returns(uint256);
    function getSupportTokens() external view returns(address[] memory);
    function rebateRewards(uint256) external view returns(uint256);
}

contract BeeSmartLens {
    function getOngoingSellOrders(IBeeSmart smart, address wallet, uint256 timestamp, uint256 maxCount) public view returns(Order[] memory) {
        uint256 length = smart.getLengthOfSellOrders(wallet);

        bytes32[] memory hashes = new bytes32[](length);
        uint count;
        for (uint i = length; i >= 1; --i) {
            bytes32 orderHash =  smart.sellOrdersOfUser(wallet, i - 1);
            Order memory ord = smart.orders(orderHash);
            if (ord.updatedAt <= timestamp &&
                (ord.status == OrderStatus.WAITING || ord.status == OrderStatus.ADJUSTED || ord.status == OrderStatus.DISPUTING)
            ) {
                hashes[count] = orderHash;
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
        bytes32[] memory hashes = new bytes32[](length);
        uint count;
        for (uint i = length; i >= 1; --i) {
            bytes32 orderHash =  smart.buyOrdersOfUser(wallet, i - 1);
            Order memory ord = smart.orders(orderHash);
            if (ord.updatedAt <= timestamp &&
                (ord.status == OrderStatus.WAITING || ord.status == OrderStatus.ADJUSTED || ord.status == OrderStatus.DISPUTING)
            ) {
                hashes[count] = orderHash;
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
        bytes32[] memory hashes = new bytes32[](length);

        uint count;
        for (uint i = length; i >= 1; --i) {
            bytes32 orderHash =  smart.sellOrdersOfUser(wallet, i - 1);
            Order memory ord = smart.orders(orderHash);
            if (ord.updatedAt <= timestamp &&
                (ord.status == OrderStatus.CONFIRMED || ord.status == OrderStatus.CANCELLED || ord.status == OrderStatus.TIMEOUT || ord.status == OrderStatus.RECALLED)
            ) {
                hashes[count] = orderHash;
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
        bytes32[] memory hashes = new bytes32[](length);

        uint count;
        for (uint i = length; i >= 1; --i) {
            bytes32 orderHash =  smart.buyOrdersOfUser(wallet, i - 1);
            Order memory ord = smart.orders(orderHash);
            if (ord.updatedAt <= timestamp &&
                (ord.status == OrderStatus.CONFIRMED || ord.status == OrderStatus.CANCELLED || ord.status == OrderStatus.TIMEOUT || ord.status == OrderStatus.RECALLED)
            ) {
                hashes[count] = orderHash;
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
            bytes32 orderHash =  smart.sellOrdersOfUser(wallet, i);
            orders[j]  = smart.orders(orderHash);
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
            bytes32 orderHash =  smart.buyOrdersOfUser(wallet, i);
            orders[j]  = smart.orders(orderHash);
            ++j;
        }

        return orders;
    }

    // read both buyer & seller order of this wallet, less than 200 orders.
    function getStatusUpdatedSellOrder(
        IBeeSmart smart,
        address wallet,
        uint256 startIndex,
        uint256 itemCount,
        uint256 updatedAfter
    ) public view returns(Order[] memory, uint256) {
        Order[] memory sellOrders = getTotalSellOrders(smart, wallet, startIndex, itemCount);
        Order[] memory result = new Order[](sellOrders.length);

        uint256 length;
        for (uint256 i = 0; i < sellOrders.length; ++i) {
            if (sellOrders[i].updatedAt >= updatedAfter) {
                result[length] = sellOrders[i];
                ++length;
            }
        }

        return (result, length);
    }

    function getStatusUpdatedBuyOrder(IBeeSmart smart,
        address wallet,
        uint256 startIndex,
        uint256 itemCount,
        uint256 updatedAfter
    ) public view returns(Order[] memory, uint256) {
        Order[] memory buyOrders = getTotalBuyOrders(smart, wallet, startIndex, itemCount);
        Order[] memory result = new Order[](buyOrders.length);

        uint256 length;
        for (uint256 i = 0; i < buyOrders.length; ++i) {
            if (buyOrders[i].updatedAt >= updatedAfter) {
                result[length] = buyOrders[i];
                ++length;
            }
        }

        return (result, length);
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