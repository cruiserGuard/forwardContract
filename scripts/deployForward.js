// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const fs = require("fs");
const settings = require("./parameters.json");



async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  //console.log("Account balance:", (await deployer.getBalance()).toString());

  const mainFactory = await ethers.getContractFactory("forwardUnit");
  console.log("initalization ready");
  const mainContract = await mainFactory.deploy(settings.buyer,settings.seller,settings.parameters,settings.feeRate);
  await mainContract.deployed();
  
  console.log("Account balance:", (await deployer.getBalance()).toString());
  console.log("Forward address:", mainContract.address);
  console.log("amount ", (await mainContract.getContent()).toString());



  // Writer Contract address to file
  const contractAddressFile = __dirname + "/mainContractAddress.json";
  fs.writeFileSync(
    contractAddressFile,
    JSON.stringify({ address: mainContract.address }, undefined, 2)
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
