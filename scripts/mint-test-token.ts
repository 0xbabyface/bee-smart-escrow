import { ethers } from "hardhat";

import {contracts} from "./env";

async function mint(token: string, to: string, amount: bigint) {
  const erc20 = await ethers.getContractAt("TestUSDT", token);
  let tx = await erc20.mint(to, amount);
  await tx.wait();

  console.log(`mint ${amount.toString()} ${await erc20.symbol()} to ${to}, ${tx.hash}`);
}

async function main() {
  const to = "0xbB2Da3f198f7f5aC4082e0f8ADF47d58FF93F604";
  await mint(contracts.TestUSDC, to, ethers.parseEther("100000"));
  await mint(contracts.TestUSDT, to, ethers.parseEther("100000"));
}

main();