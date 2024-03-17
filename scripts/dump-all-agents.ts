import { ethers } from "hardhat";

import {contracts} from "./env";

interface Agent {
    selfId: bigint;
    selfWallet: string;
    parentId: bigint;
    starLevel: number;
    canAddsubAgent: boolean;
    removed: boolean;
    nickName: string;
}
async function main() {
  // const lens = await ethers.getContractAt('ManagementLens', contracts.ManagementLens);

  // // const agents = await lens.getAgentInfo(contracts.BeeSmartProxy, '0x000000000000000000000000000000000000dEaD');
  // const agents = await lens.getAgentInfo(contracts.BeeSmartProxy, '0x55a0e984bC0C2650a16E2300a372b1D94CbD3E63');
  // console.log(`${agents}`)
  // console.log(`selfId:          ${agents[0]}`);
  // console.log(`selfWallet:      ${agents[1]}`);
  // console.log(`parentId:        ${agents[2]}`);
  // console.log(`starLevel:       ${agents[3]}`);
  // console.log(`canAddSubAgent:  ${agents[4]}`);
  // console.log(`removed:         ${agents[5]}`);
  // console.log(`isGlobalAgent:   ${agents[6]}`);
  // console.log(`subAgents:       ${agents[7]}`);

  const agentManager = await ethers.getContractAt('AgentManager', contracts.AgentManagerProxy);

  const totalAgentsCount = await agentManager.totalAgents();
  console.log(`total: ${totalAgentsCount}`)

  const rootId = await agentManager.RootId();

  for (let i = 1; i <= totalAgentsCount; i++) {
    const aid = rootId + BigInt(i);
    const a = await agentManager.agentId2Wallet(aid);

    console.log(`${aid} => ${a}`);
    const wallet = await agentManager.agentId2Wallet(rootId + BigInt(i));
    // console.log(`${JSON.stringify(agent, null, "  ")}`);
    const subAgents = await agentManager.getSubAgents(wallet);
    if (subAgents.length > 0)
      console.log(`${wallet},  subAgents: ${subAgents}`);
  }
}

main();