import { ethers } from "hardhat";

import {contracts} from "./env";


async function make_order(smart: any, signer: any, buyer: string) {
  const orderHash = ethers.keccak256(`0x0${Date.now()}`);

  let tx = await smart.connect(signer).makeOrder(orderHash, contracts.TestUSDT, ethers.parseEther("200"), buyer);
  await tx.wait();

  return orderHash;
}

async function adjust_order(smart: any, signer: any, orderHash: string, amount: bigint) {
  let tx = await smart.connect(signer).adjustOrder(orderHash, amount);
  await tx.wait();
}

async function confirm_order(smart: any, signer: any, orderHash: string) {
  let tx = await smart.connect(signer).confirmOrder(orderHash);
  await tx.wait();
}

async function main() {
  const [seller, buyer] = await ethers.getSigners();
  const smart = await ethers.getContractAt("BeeSmart", contracts.BeeSmartProxy);

  // const usdt = await ethers.getContractAt("TestUSDT", contracts.TestUSDT);
  // await usdt.mint(seller.address, ethers.parseEther("100000"));

  // await usdt.connect(seller).approve(smart.target, ethers.parseEther("1000"));

  // await adjust_order(smart, buyer, "0x8784f5afb71b4ca64558fdcdbf29ba88ad34ea261da5d3b31f1a30e545de56b8", ethers.parseEther("123"));

  await confirm_order(smart, seller,  "0x45923384c0807003bdc7fee26d504c7520939b37d75153fc0afa5b4f9065dc27");

}

main();