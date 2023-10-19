import { ethers } from "hardhat";

import * as t from "../deploy_info.json";

const TT = t.local;

async function main() {
  const [wallet] = await ethers.getSigners() ;
  const lens = await ethers.getContractAt("BeeSmartLens", TT.BeeSmartLens);

  const userInfo = await lens.getUserInfo(TT.BeeSmartProxy, wallet.address);

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

}

main();