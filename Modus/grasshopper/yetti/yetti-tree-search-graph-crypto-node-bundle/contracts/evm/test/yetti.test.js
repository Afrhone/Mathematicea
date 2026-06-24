const { expect } = require("chai");
const { ethers } = require("hardhat");
describe("YETTI", function () {
  it("deploys token", async function () {
    const Token = await ethers.getContractFactory("YettiSnowCredits");
    const token = await Token.deploy(1000n);
    expect(await token.totalSupply()).to.equal(1000n);
  });
});
