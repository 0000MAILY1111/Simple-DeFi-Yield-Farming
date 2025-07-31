const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.provider.getBalance(deployer.address)).toString());

  // Deploy LP Token
  const LPToken = await ethers.getContractFactory("LPToken");
  const lpToken = await LPToken.deploy();
  await lpToken.waitForDeployment();
  console.log("LP Token deployed to:", await lpToken.getAddress());

  // Deploy DAPP Token
  const DappToken = await ethers.getContractFactory("DappToken");
  const dappToken = await DappToken.deploy();
  await dappToken.waitForDeployment();
  console.log("DAPP Token deployed to:", await dappToken.getAddress());

  // Deploy Token Farm
  const TokenFarm = await ethers.getContractFactory("TokenFarm");
  const tokenFarm = await TokenFarm.deploy(
    await lpToken.getAddress(),
    await dappToken.getAddress()
  );
  await tokenFarm.waitForDeployment();
  console.log("Token Farm deployed to:", await tokenFarm.getAddress());

  // Transfer DAPP tokens to farm for rewards
  const transferAmount = ethers.parseEther("5000000"); // 5M tokens for rewards
  await dappToken.transfer(await tokenFarm.getAddress(), transferAmount);
  console.log("Transferred 5M DAPP tokens to farm for rewards");

  // Mint some LP tokens to deployer for testing
  const lpAmount = ethers.parseEther("10000");
  await lpToken.mint(deployer.address, lpAmount);
  console.log("Minted 10k LP tokens to deployer for testing");

  console.log("\n=== Contract Addresses ===");
  console.log("LP Token:", await lpToken.getAddress());
  console.log("DAPP Token:", await dappToken.getAddress());
  console.log("Token Farm:", await tokenFarm.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });