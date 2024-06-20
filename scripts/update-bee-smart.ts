import { ethers } from "hardhat";
import {contracts} from "./env";

async function main() {
  const BeeSmart = await ethers.deployContract("BeeSmart");
  await BeeSmart.waitForDeployment();

  const proxy = await ethers.getContractAt("CommonProxy", contracts.BeeSmartProxy);
  let tx = await proxy.setImplementation(BeeSmart.target, "0x");
  await tx.wait();

  console.log(`update bee smart to ${BeeSmart.target} : ${tx.hash}`);
}

main();
