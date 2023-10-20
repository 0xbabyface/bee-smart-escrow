import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {
  const [seller, buyer] = await ethers.getSigners();
  const smart = await ethers.getContractAt("BeeSmart", contracts.BeeSmartProxy);

  const usdt = await ethers.getContractAt("TestUSDT", contracts.TestUSDT);
  await usdt.mint(seller.address, ethers.parseEther("100000"));

  await usdt.connect(seller).approve(smart.target, ethers.parseEther("1000"));

  const orderHash = ethers.keccak256(`0x0${Date.now()}`);

  let tx = await smart.connect(seller).makeOrder(orderHash, contracts.TestUSDT, ethers.parseEther("200"), buyer.address);
  await tx.wait();

  console.log(`${seller.address} sell order count: ${await smart.getLengthOfSellOrders(seller.address)}`);
  console.log(`${buyer.address} buyer order count: ${await smart.getLengthOfBuyOrders(buyer.address)}`);

}

main();