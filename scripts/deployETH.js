
const hre = require("hardhat");
const fs = require("fs");
const { BigNumber, utils, provider } = ethers;
const toWei = (value) => utils.parseEther(value.toString());
const fromWei = (value) =>
  utils.formatEther(typeof value === "string" ? value : value.toString());

async function main() {
  [deployer, user1, user2] = await ethers.getSigners();


  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const tokenFactory = await ethers.getContractFactory("WETH9A");
  const tokenContract = await tokenFactory.deploy();
  await tokenContract.deployed();
  console.log("ETH address:", tokenContract.address);

  //Writer Contract address to file
  const contractAddressFile = __dirname + "/tokenContractaddress.json";
  fs.writeFileSync(
    contractAddressFile,
    JSON.stringify({ address: tokenContract.address }, undefined, 2)
  );

  var amount = toWei(5);

  //await tokenContract.connect(deployer).deposit(({ value: amount }));
  await tokenContract.connect(user1).deposit(({ value: amount }));
  await tokenContract.connect(user2).deposit(({ value: amount }));

  console.log("deployer at ", (await tokenContract.totalSupply()).toString());
  console.log("user1 balance at ", (await tokenContract.balanceOf(user1.address)).toString());
  console.log("user2 balance at ", (await tokenContract.balanceOf(user2.address)).toString());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
