import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {
  const smart = await ethers.getContractAt("BeeSmart", contracts.BeeSmartProxy);
  /* reset Reputation */
  // const r = await ethers.deployContract("Reputation");
  // await r.waitForDeployment();
  // console.log('r: ', r.target);
  // let tx = await smart.setReputation(r.target);
  // await tx.wait();

  /* reset Relationship */
  const r = await ethers.deployContract("Relationship");
  await r.waitForDeployment();
  console.log('r: ', r.target);
  let tx = await smart.setRelationship(r.target);
  await tx.wait();

  /* reset community wallet*/
  // await smart.setCommunityWallet("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
}

main();
