import { ethers } from "hardhat";
import {contracts} from "./env";

async function main() {
  const AgentManager = await ethers.getContractAt("AgentManager", contracts.AgentManagerProxy);

  console.log(`${await AgentManager.getAgentByWallet('0xb5DFdD7B4d67ae75D5A800B490ee4356e2DC1f97')}`)
}

main();
