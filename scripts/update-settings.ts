import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {
  const r = await ethers.deployContract("Reputation");
  await r.waitForDeployment();
  console.log('r: ', r.target);

  const smart = await ethers.getContractAt("BeeSmart", contracts.BeeSmartProxy);
  let tx = await smart.setReputation(r.target);
  await tx.wait();
}

main();
