import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {
  const smart = await ethers.getContractAt("BeeSmart", contracts.BeeSmartProxy);

  const communityWallet = await smart.communityWallet();
  const globalWallet = await smart.globalShareWallet();

  console.log(`totalOrdersCount:          ${await smart.totalOrdersCount()}`);
  console.log(`reputation contract:       ${await smart.reputation()}`);
  console.log(`communityWallet:           ${communityWallet}`);
  console.log(`globalWallet:              ${globalWallet}`);
  console.log(`communityFeeRatio:         ${ethers.formatEther(await smart.communityFeeRatio())}`);
  console.log(`operatorFeeRatio:          ${ethers.formatEther(await smart.operatorFeeRatio())}`);
  console.log(`globalFeeRatio:            ${ethers.formatEther(await smart.globalShareFeeRatio())}`);
  console.log(`sameLevelFeeRatio:         ${ethers.formatEther(await smart.sameLevelFeeRatio())}`);
  console.log(`chargesBaredBuyerRatio:    ${ethers.formatEther(await smart.chargesBaredBuyerRatio())}`);
  console.log(`chargesBaredSellerRatio:   ${ethers.formatEther(await smart.chargesBaredSellerRatio())}`);
  console.log(`communityPending:          ${ethers.formatEther(await smart.pendingRewards(communityWallet, contracts.TestUSDT))}`);
  console.log(`globalPending:             ${ethers.formatEther(await smart.pendingRewards(globalWallet, contracts.TestUSDT))}`);

  console.log(`orderStatusDurationSec:    ${await smart.orderStatusDurationSec()}`);
  console.log(`reputationRatio:           ${ethers.formatEther(await smart.reputationRatio())}`)

  console.log(`hasRole: ${await smart.hasRole(await smart.AdminRole(), "0x81bD01D0A9E8e8E40FAf22B779Bb21BaFbf8f7AC")}`)
}

main();