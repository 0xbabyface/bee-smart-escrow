import { ethers } from "hardhat";

import {contracts} from "./env";

async function mint(token: string, to: string, amount: bigint) {
  const erc20 = await ethers.getContractAt("TestUSDT", token);
  let tx = await erc20.mint(to, amount);
  await tx.wait();

  console.log(`mint ${amount.toString()} ${await erc20.symbol()} to ${to}, ${tx.hash}`);
}

async function main() {
  // const to = "0x18d3C20a79fbCeb89fA1DAd8831dcF6EBbe27491"; // balder
  // const to = "0x07CDf691D92e829767Bea386fC5E5b3fa99EC38b"; // alex
  const to = "0x987E16b4f518B62f1e856AC36336d0d849Aaa527"; // edmond
  const to1 = "0xb20191CbeD6c9d9122b787Ee2bbbD758FD5287CE"; // ken
  // const to = "0xbB2Da3f198f7f5aC4082e0f8ADF47d58FF93F604"; // enpeng
  await mint(contracts.TestUSDC, to, ethers.parseEther("1000000000000"));
  await mint(contracts.TestUSDT, to, ethers.parseEther("1000000000000"));
  // await mint(contracts.TestUSDC, to1, ethers.parseEther("1000000000000"));
  // await mint(contracts.TestUSDT, to1, ethers.parseEther("1000000000000"));
}

main();