import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {
  const [seller, buyer] = await ethers.getSigners();
  const Management = await ethers.getContractAt('ManagementLens', contracts.ManagementLens);

  // const settings = await Management.getSysSettings(contracts.BeeSmartProxy);
  // console.log(`settings: ${settings}`);

  // const userInfo = await Management.getRole('0xBE4480961A4d7cC29833f4378eF7bdF4D838C8D7', '0x6B26D93522511fa0c64107235402c40B18Cd42b3');
  // const userInfo = await Management.getRole(contracts.BeeSmartProxy, '0x81bD01D0A9E8e8E40FAf22B779Bb21BaFbf8f7AC');
  const userInfo = await Management.getRole(contracts.BeeSmartProxy, '0x034D1E01eFA6024E25E80C1225A8A8BD49d1E558');
  console.log(`userInfo: ${userInfo}`);

  // const agentInfo = await Management.getAgentInfo(contracts.BeeSmartProxy, seller.address);
  // console.log(`agent: ${agentInfo}`);

  // const histtoryOrders = await Management.getRebateInfo(contracts.BeeSmartProxy, 100000001, 0, 25);
  // console.log(`100000004: ${histtoryOrders}`);
}

main();