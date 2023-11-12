import { ethers } from "hardhat";

import {contracts} from "./env";

function orderStatus(index: bigint) {
  // console.log('order status: ', index)
  switch (index) {
    case 0n: return "unknown";
    case 1n: return "normal";
    case 2n: return "adjusted";
    case 3n: return "confirmed";
    case 4n: return "canceled";
    case 5n: return "sellerDisputing";
    case 6n: return "buyerDisputing";
    case 7n: return "locked";
    case 8n: return "sellerwin";
    case 9n: return "buyerwin";
    default: return "error";
  }
}

async function tokenSymbol(addr: string) {
  const erc20 = await ethers.getContractAt("TestUSDC", addr);
  return await erc20.symbol();
}

async function main() {
  const [seller, buyer] = await ethers.getSigners() ;
  // const seller = {address: "0xb20191CbeD6c9d9122b787Ee2bbbD758FD5287CE"}
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
    for (let i = 0; i < orders.length; i++) {
      const o = orders[i];
      console.log(`
        orderId:        ${o[0]}
        sellAmount:     ${ethers.formatEther(o[1])}
        paytoken:       ${await tokenSymbol(o[2])}
        updatedAt:      ${o[3]}
        buyer:          ${o[4]}
        seller:         ${o[5]}
        currStatus:     ${orderStatus(o[6])}
        prevStatus:     ${orderStatus(o[7])}
        sellerFee:      ${ethers.formatEther(o[5])}
        buyerFee:       ${ethers.formatEther(o[5])}
      `)
    }
  };

  const sellOrders = await lens.getOngoingSellOrders(contracts.BeeSmartProxy, seller.address, Math.floor(Date.now() / 1000), 100);
  // console.log(`${seller.address} seller orders: ${sellOrders}`);
  await printOrder("------ ongoing sell order ------ ", sellOrders);

  const buyOrders = await lens.getOngoingBuyOrders(contracts.BeeSmartProxy, seller.address, Math.floor(Date.now() / 1000), 100);
  // console.log(`${buyer.address} buyer orders: ${buyOrders}`);
  await printOrder("----- ongoing buy order ------ ", buyOrders);

  const printFinishedOrder = async (tag: string, orders: any[], rewards: any[]) => {
    console.log(tag, ' ', orders.length);
    for (let i = 0; i < orders.length; i++) {
      const o = orders[i];
      const rw = rewards[i];

      console.log(`
        orderId:             ${o[0]}
        sellAmount:          ${ethers.formatEther(o[1])}
        paytoken:            ${await tokenSymbol(o[2])}
        updatedAt:           ${o[3]}
        buyer:               ${o[4]}
        seller:              ${o[5]}
        currStatus:          ${orderStatus(o[6])}
        prevStatus:          ${orderStatus(o[7])}
        sellerFee:           ${ethers.formatEther(o[5])}
        buyerFee:            ${ethers.formatEther(o[5])}
        buyerRewards:        ${ethers.formatEther(rw[0])}
        sellerRewards:       ${ethers.formatEther(rw[1])}
        buyerAirdropPoints:  ${rw[2]}
        sellerAirdropPoints: ${rw[3]}
        buyerReputation:     ${ethers.formatEther(rw[4])}
        sellerReputation:    ${ethers.formatEther(rw[5])}
      `)
    }
  }
  const [hSellOrder, hSellReward] = await lens.getHistorySellOrders(contracts.BeeSmartProxy, seller.address, Math.floor(Date.now() / 1000), 100);
  await printFinishedOrder("history sell order: ", hSellOrder, hSellReward);

  const [hBuyOrder, hBuyReward] = await lens.getHistoryBuyOrders(contracts.BeeSmartProxy, seller.address, Math.floor(Date.now() / 1000), 100);
  await printFinishedOrder("history buy order: ", hBuyOrder, hBuyReward);

  const sellUpdatedOrders = await lens.getStatusUpdatedSellOrder(contracts.BeeSmartProxy, seller.address, 100, Math.floor(Date.now() / 1000) - 86400);
  await printOrder("status updated sell order: ", sellUpdatedOrders);

  const buyUPdatedOrders = await lens.getStatusUpdatedBuyOrder(contracts.BeeSmartProxy, seller.address, 100, Math.floor(Date.now() / 1000) - 86400);
  await printOrder("status updated buy order: ", buyUPdatedOrders);
}

main();
