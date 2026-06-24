const hre = require("hardhat");

async function main() {
  const NamespaceAuthority = await hre.ethers.getContractFactory("NamespaceAuthority");
  const ns = await NamespaceAuthority.deploy();
  await ns.waitForDeployment();

  const OctopuceDAO = await hre.ethers.getContractFactory("OctopuceDAO");
  const dao = await OctopuceDAO.deploy();
  await dao.waitForDeployment();

  const NFT = await hre.ethers.getContractFactory("GenerativeEntityNFT");
  const nft = await NFT.deploy(await ns.getAddress());
  await nft.waitForDeployment();

  console.log(JSON.stringify({
    NamespaceAuthority: await ns.getAddress(),
    OctopuceDAO: await dao.getAddress(),
    GenerativeEntityNFT: await nft.getAddress()
  }, null, 2));
}

main().catch((e) => { console.error(e); process.exit(1); });
