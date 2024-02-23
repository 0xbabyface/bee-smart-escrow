import { ethers } from "hardhat";
import {contracts} from "./env";

async function main() {
  const AgentManager = await ethers.deployContract("AgentManager");
  await AgentManager.waitForDeployment();

  const proxy = await ethers.getContractAt("CommonProxy", contracts.AgentManagerProxy);
  let tx = await proxy.setImplementation(AgentManager.target, "0x");
  await tx.wait();

  console.log(`update agentmanager to ${AgentManager.target} : ${tx.hash}`);
}

main();
