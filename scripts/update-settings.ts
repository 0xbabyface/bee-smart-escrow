import { ethers } from "hardhat";

import * as t from "../deploy_info.json";

const TT = t.mumbai;

async function main() {
  const r = await ethers.deployContract("Reputation");
  await r.waitForDeployment();
  console.log('r: ', r.target);

  const smart = await ethers.getContractAt("BeeSmart", TT.BeeSmartProxy);
  let tx = await smart.setReputation(r.target);
  await tx.wait();
}

main();
