import { ethers } from "hardhat";

import {contracts} from "./env";

async function main() {
  const [owner] = await ethers.getSigners();
  const smart = await ethers.getContractAt("BeeSmart", contracts.BeeSmartProxy);
  /* reset Reputation */
  // const r = await ethers.deployContract("Reputation");
  // await r.waitForDeployment();
  // console.log('r: ', r.target);
  // let tx = await smart.setReputation(r.target);
  // await tx.wait();

  /* reset community wallet*/
  // await smart.setCommunityWallet("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
  // await smart.setReputationRatio(ethers.parseEther("1.0"));  //  1 : 1 for candy
  // await smart.setOrderStatusDurationSec(60);  // order wait for 30 minutes then can disputing
  // await smart.setRole(await smart.CommunityRole(), '0xD322648503F2eb2Da7B875D98c7169584392C634', true); // enpeng
  await smart.setRole(await smart.CommunityRole(), '0xCac9b9BaC8dfa87c1Cb4297B616c788605eB4f9F', true); // edmond
}

main();
