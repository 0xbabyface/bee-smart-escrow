import { ethers } from "hardhat";

import {contracts} from "./env";


async function main() {
  const [seller, buyer] = await ethers.getSigners() ;
  const lens = await ethers.getContractAt("BeeSmartLens", contracts.BeeSmartLens);

  const userInfo = await lens.getUserInfo(contracts.BeeSmartProxy, seller.address);

  const printAssetInfo = (a: any[][]) => {
    for (let i = 0; i < a.length; i++) {
      console.log(`
        token:  ${a[i][0]}
        symbol: ${a[i][1]}
        decimals: ${a[i][2]}
        balance:  ${ethers.formatUnits(a[i][3], 18)}
      `)
    }
  }
  console.log(`
    userInfo:
      relationId:      ${userInfo[0]}
      airdropCount:    ${userInfo[1]}
      reputationCount: ${userInfo[2]}
      totalTrades:     ${userInfo[3]}
      rebateAmount:    ${userInfo[4]}
    `);
    printAssetInfo(userInfo[5])

  const sellOrders = await lens.getTotalSellOrders(contracts.BeeSmartProxy, seller.address, 0, 100);
  console.log(`${seller.address} seller orders: ${sellOrders}`);

  const buyOrders = await lens.getTotalBuyOrders(contracts.BeeSmartProxy, buyer.address, 0, 100);
  console.log(`${buyer.address} buyer orders: ${buyOrders}`);

}

main();