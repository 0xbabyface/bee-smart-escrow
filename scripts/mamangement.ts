import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {
  const [seller, buyer] = await ethers.getSigners();
  const Management = await ethers.getContractAt('ManagementLens', contracts.ManagementLens);

  const settings = await Management.getSysSettings(contracts.BeeSmartProxy);
  console.log(`settings: ${settings}`);

  const userInfo = await Management.getRole(contracts.BeeSmartProxy, seller.address);
  console.log(`userInfo: ${userInfo}`);

  const agentInfo = await Management.getAgentInfo(contracts.BeeSmartProxy, seller.address);
  console.log(`agent: ${agentInfo}`);
}

main();