import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {

  const relationship = await ethers.getContractAt("Relationship", contracts.Relationship);

  const tx = await relationship.bind(100000000, 0);
  await tx.wait();

  console.log(`register: ${tx.hash}`);

}

main();