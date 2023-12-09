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

  /* reset Relationship */
  // const r = await ethers.deployContract("Relationship");
  // await r.waitForDeployment();
  // console.log('r: ', r.target);
  // let tx = await smart.setRelationship(r.target);
  // await tx.wait();

  /* reset community wallet*/
  // await smart.setCommunityWallet("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")

  // await smart.setCommunityFeeRatio(
  //   ethers.parseEther("0.03"),  // community fee ratio
  //   ethers.parseEther("1.0"),   // buyer charged
  //   ethers.parseEther("0.0")    // seller charged
  // );

  // await smart.setRewardFeeRatio(
  //   ethers.parseEther("0.03"),  // reward ratio for buyer
  //   ethers.parseEther("0.03")   // reward ratio for seller
  // );

  // await smart.setReputationRatio(ethers.parseEther("1.0"));  //  1 : 1 for candy
  // await smart.setRebateRatio(ethers.parseEther("0.1"));   // rebate ratio 10%

  // await smart.setOrderStatusDurationSec(60);  // order wait for 30 minutes then can disputing

  // await smart.setFinancialWallet(owner.address);
  // await smart.setRewardToken("0x4621249fE360256992D504FDe9b35c801a17012e");

  // await smart.setRole(await smart.CommunityRole(), '0xD322648503F2eb2Da7B875D98c7169584392C634', true); // enpeng
  await smart.setRole(await smart.CommunityRole(), '0xCac9b9BaC8dfa87c1Cb4297B616c788605eB4f9F', true); // edmond
}

main();
