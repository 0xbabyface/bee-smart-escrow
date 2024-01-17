import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {
  const smart = await ethers.getContractAt("BeeSmart", contracts.BeeSmartProxy);

  console.log(`totalOrdersCount:          ${await smart.totalOrdersCount()}`);
  console.log(`relationship contract:     ${await smart.relationship()}`);
  console.log(`reputation contract:       ${await smart.reputation()}`);
  console.log(`communityWallet:           ${await smart.communityWallet()}`);
  console.log(`orderStatusDurationSec:    ${await smart.orderStatusDurationSec()}`);
  console.log(`communityFeeRatio:         ${ethers.formatEther(await smart.communityFeeRatio())}`);
  console.log(`chargesBaredBuyerRatio:    ${ethers.formatEther(await smart.chargesBaredBuyerRatio())}`);
  console.log(`chargesBaredSellerRatio:   ${ethers.formatEther(await smart.chargesBaredSellerRatio())}`);
  console.log(`reputationRatio:           ${ethers.formatEther(await smart.reputationRatio())}`)
}

main();