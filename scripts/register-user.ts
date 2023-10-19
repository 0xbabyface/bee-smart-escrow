import { ethers } from "hardhat";

import * as TT from "../deploy_info.json";

async function main() {

  const relationship = await ethers.getContractAt("Relationship", TT.local.Relationship);

  const tx = await relationship.bind(8888888888, 0);
  await tx.wait();

  console.log(`register: ${tx.hash}`);

}

main();