// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

enum OrderStatus { UNKNOWN, WAITING, CONFIRMED, CANCELLED, TIMEOUT, DISPUTING, RECALLED }
struct Order {
    address payToken;
    uint256 sellAmount;
    address buyer;
    address seller;
    OrderStatus status;
    uint64  updatedAt;
}

interface IBeeSmart {
    function getLengthOfSellOrders(address) external view returns(uint256);
    function getLengthOfBuyOrders(address) external view returns(uint256);
    function sellOrdersOfUser(address, uint256) external view returns(bytes32);
    function buyOrdersOfUser(address, uint256) external view returns(bytes32);
    function orders(bytes32) external view returns(Order memory);
}

contract BeeSmartLens {

    function getTotalSellOrders(IBeeSmart smart, address wallet, uint256 lastN) public view returns(Order[] memory) {
        uint256 length = smart.getLengthOfSellOrders(wallet);
        uint256 count = length > lastN ? lastN : length;
        Order[] memory orders = new Order[](count);

        uint256 j = 0;
        for (uint i = length - 1; i >= count; --i) {
            bytes32 orderHash =  smart.sellOrdersOfUser(wallet, i);
            orders[j]  = smart.orders(orderHash);
            ++j;
        }

        return orders;
    }

    function getTotalBuyOrders(IBeeSmart smart, address wallet, uint256 lastN) public view returns(Order[] memory) {
        uint256 length = smart.getLengthOfBuyOrders(wallet);
        uint256 count = length > lastN ? lastN : length;
        Order[] memory orders = new Order[](count);

        uint256 j = 0;
        for (uint i = length - 1; i >= count; --i) {
            bytes32 orderHash =  smart.buyOrdersOfUser(wallet, i);
            orders[j]  = smart.orders(orderHash);
            ++j;
        }

        return orders;
    }

    // read both buyer & seller order of this wallet, less than 200 orders.
    function getStatusUpdatedOrder(IBeeSmart smart, address wallet, uint256 updatedAfter) public view returns(Order[] memory, uint256) {
        Order[] memory sellOrders = getTotalSellOrders(smart, wallet, 100);
        Order[] memory buyOrders = getTotalBuyOrders(smart, wallet, 100);
        Order[] memory result = new Order[](sellOrders.length + buyOrders.length);

        uint256 length;
        for (uint256 i = 0; i < sellOrders.length; ++i) {
            if (sellOrders[i].updatedAt >= updatedAfter) {
                result[length] = sellOrders[i];
                ++length;
            }
        }

        for (uint256 i = 0; i < buyOrders.length; ++i) {
            if (buyOrders[i].updatedAt >= updatedAfter) {
                result[length] = buyOrders[i];
                ++length;
            }
        }

        return (result, length);
    }
}