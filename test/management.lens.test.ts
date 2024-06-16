import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { deployBeeSmarts } from "./common";
import { ethers } from "hardhat";

describe("ManagementLens", async function () {

  it("operator", async () => {
    const {smart, operator} = await loadFixture(deployBeeSmarts);

    const lens = await ethers.deployContract("ManagementLens");
    await lens.waitForDeployment();
    console.log(`opeator: ${operator.address}`)
    const m = await lens.getAgentInfoByOperator(smart.target, operator.address);
    console.log(`${m}`);

  })
});
