import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {
  const smart = await ethers.getContractAt("BeeSmart", contracts.BeeSmartProxy);

  console.log(`reputationRatio: ${ethers.formatEther(await smart.reputationRatio())}`)
  console.log(`rebateRatio:     ${ethers.formatEther(await smart.rebateRatio())}`)
  console.log(`orderRewards:     ${await smart.orderRewards("0x6ba1b063114d85c42bbf9a10fc4c3162ed9b0aef5f4b4c2b63b5097631096cdf")}`)
  console.log(`orders      :     ${await smart.orders("0x6ba1b063114d85c42bbf9a10fc4c3162ed9b0aef5f4b4c2b63b5097631096cdf")}`)

  const rep = await ethers.getContractAt("Reputation", contracts.Reputation);
  console.log(`rep:     ${await rep.reputationPoints(contracts.BeeSmartProxy, 100000004)}`)

}

main();