import { ethers } from "hardhat";
import {contracts} from "./env";

async function main() {
  const smart = await ethers.getContractAt('BeeSmart', contracts.BeeSmartProxy);

  // const boundAgent = await smart.boundAgents('0xC99ffDAd33837655aCA4c396Ef3c21B56c83BA5E');
  // const boundAgent = await smart.boundAgents('0xB714DcAeA7080a91eD3D38de35a35bEB7Fa0A242');

  // const userId = BigInt(boundAgent) >> BigInt(96);
  // const agentId = BigInt(boundAgent) & BigInt('0xffffffffffffffff');

  // console.log(`userId: ${userId}, agentId: ${agentId}`);


  console.log(`${await smart.operatorWallets2Id('0xb5DFdD7B4d67ae75D5A800B490ee4356e2DC1f97')}`)
}

main();