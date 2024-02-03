import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {
  const lens = await ethers.getContractAt('ManagementLens', contracts.ManagementLens);

  // const agents = await lens.getAgentInfo(contracts.BeeSmartProxy, '0x000000000000000000000000000000000000dEaD');
  const agents = await lens.getAgentInfo(contracts.BeeSmartProxy, '0x55a0e984bC0C2650a16E2300a372b1D94CbD3E63');
  console.log(`${agents}`)
  console.log(`selfId:          ${agents[0]}`);
  console.log(`selfWallet:      ${agents[1]}`);
  console.log(`parentId:        ${agents[2]}`);
  console.log(`starLevel:       ${agents[3]}`);
  console.log(`canAddSubAgent:  ${agents[4]}`);
  console.log(`removed:         ${agents[5]}`);
  console.log(`isGlobalAgent:   ${agents[6]}`);
  console.log(`subAgents:       ${agents[7]}`);
}

main();