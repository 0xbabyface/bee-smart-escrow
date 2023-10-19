import { ethers } from "hardhat";

import * as TT from "../deploy_info.json";

async function mint(token: string, to: string, amount: bigint) {
  const erc20 = await ethers.getContractAt("TestUSDT", token);
  let tx = await erc20.mint(to, amount);
  await tx.wait();

  console.log(`mint ${amount.toString()} ${await erc20.symbol()} to ${to}, ${tx.hash}`);
}

async function main() {
  const to = "";
  await mint(TT.mumbai.TestUSDC, to, ethers.parseEther("100000"));
  await mint(TT.mumbai.TestUSDT, to, ethers.parseEther("100000"));
}

main();