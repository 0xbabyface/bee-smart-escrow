import { ethers } from "hardhat";

import {contracts} from "./env";

function orderStatus(index: bigint) {
  // console.log('order status: ', index)
  switch (index) {
    case 0n: return "unknown";
    case 1n: return "waiting";
    case 2n: return "adjusted";
    case 3n: return "confirmed";
    case 4n: return "canceled";
    case 5n: return "timeout";
    case 6n: return "disputing";
    case 7n: return "recalled";
    default: return "error";
  }
}

async function tokenSymbol(addr: string) {
  const erc20 = await ethers.getContractAt("TestUSDC", addr);
  return await erc20.symbol();
}

async function main() {
  const [seller, buyer] = await ethers.getSigners() ;
  const lens = await ethers.getContractAt("BeeSmartLens", contracts.BeeSmartLens);

  const userInfo = await lens.getUserInfo(contracts.BeeSmartProxy, seller.address);

  const printAssetInfo = (a: any[][]) => {
    console.log("MyAsset");
    for (let i = 0; i < a.length; i++) {
      console.log(`
        token:  ${a[i][0]}
        symbol: ${a[i][1]}
        decimals: ${a[i][2]}
        balance:  ${ethers.formatUnits(a[i][3], 18)}
      `)
    }
  }
  console.log("userInfo:")
  console.log(`
      relationId:      ${userInfo[0]}
      airdropCount:    ${userInfo[1]}
      reputationCount: ${userInfo[2]}
      totalTrades:     ${userInfo[3]}
      rebateAmount:    ${userInfo[4]}
  `);
    printAssetInfo(userInfo[5])

  const printOrder = async (tag: string, orders: any[]) => {
    console.log(tag, ' ', orders.length);
    for (let o of orders) {
      console.log(`
        orderHash:  ${o[0]}
        paytoken:   ${await tokenSymbol(o[1])}
        sellAmount: ${ethers.formatEther(o[2])}
        buyer:      ${o[3]}
        seller:     ${o[4]}
        status:     ${orderStatus(o[5])}
        updatedAt:  ${o[6]}
      `)
    }
  };

  const sellOrders = await lens.getTotalSellOrders(contracts.BeeSmartProxy, seller.address, 0, 100);
  // console.log(`${seller.address} seller orders: ${sellOrders}`);
  await printOrder("sell order: ", sellOrders);

  const buyOrders = await lens.getTotalBuyOrders(contracts.BeeSmartProxy, seller.address, 0, 100);
  // console.log(`${buyer.address} buyer orders: ${buyOrders}`);
  await printOrder("buy order: ", buyOrders);

  const [sellUpdatedOrders, length1] = await lens.getStatusUpdatedSellOrder(contracts.BeeSmartProxy, seller.address, 0, 100, Math.floor(Date.now() / 1000) - 86400);
  await printOrder("status updated sell order: ", sellUpdatedOrders);

  const [buyUPdatedOrders, length2] = await lens.getStatusUpdatedBuyOrder(contracts.BeeSmartProxy, seller.address, 0, 100, Math.floor(Date.now() / 1000) - 86400);
  await printOrder("status updated buy order: ", buyUPdatedOrders);
}

main();