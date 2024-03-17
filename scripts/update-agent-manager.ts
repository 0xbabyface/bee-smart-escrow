import { ethers } from "hardhat";
import {contracts} from "./env";

async function main() {
  const AgentManager = await ethers.deployContract("AgentManager");
  await AgentManager.waitForDeployment();

  // const calldata = AgentManager.interface.encodeFunctionData("reinit", []);
  const proxy = await ethers.getContractAt("CommonProxy", contracts.AgentManagerProxy);
  let tx = await proxy.setImplementation(AgentManager.target, "0x");
  await tx.wait();

  console.log(`update agentmanager to ${AgentManager.target} : ${tx.hash}`);

  let amNew = await ethers.getContractAt('AgentManager', contracts.AgentManagerProxy);
  tx = await amNew.fix();
  await tx.wait();
}

main();
