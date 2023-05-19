// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const fs = require("fs");
const settings = require("./parameters.json");

const unit = 1;
var jsonFile = "./artifacts/contracts/WETH.sol/WETH9.json";
var parsed = JSON.parse(fs.readFileSync(jsonFile));
var WETH9 = parsed.abi;
//const { WETH9 } = require("./abi/WETH9.json");
// import WETH9 from '../artifacts/contracts/WETH.sol/WETH9.json';
var buyer = settings.buyer;
var seller = settings.seller;

async function main() {
  const [deployer, user1, user2] = await ethers.getSigners();

  user1.privateKey = buyer;
  user2.privateKey = seller;

  console.log("Deploying contracts with the account:", deployer.address);

  //console.log("Account balance:", (await deployer.getBalance()).toString());

  const mainFactory = await ethers.getContractFactory("forwardUnit");
  console.log("initalization ready");

  const mainContract = await mainFactory.deploy(buyer, seller, settings.parameters, settings.feeRate);
  await mainContract.deployed();
  const addressETH = settings.parameters.token;
  //console.log("token ", WETH9);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  console.log("Forward address:", mainContract.address);
  console.log("amount ", (await mainContract.getContent()).toString());

  const Token = new ethers.Contract(addressETH, WETH9, deployer);
  console.log("buyer", (await Token.balanceOf(buyer)));
  console.log("seller", (await Token.balanceOf(seller)));
  console.log("contract", (await Token.balanceOf(mainContract.address)));
  // console.log(await Token.totalSupply());
  // console.log(await Token.symbol());
  console.log("buyamount ", (await mainContract.buyAmount()));
  console.log("sellamount ", (await mainContract.sellAmount()));
  let buyamount = await mainContract.buyAmount();
  let sellamount = await mainContract.sellAmount();

  let t1 = (await Token.allowance(buyer, mainContract.address)).toNumber();
  if (t1 === 0) {
    // console.log("buyer approve amount");
    await Token.connect(user1).approve(mainContract.address, buyamount + unit);
  }

  let t2 = (await Token.allowance(seller, mainContract.address)).toNumber();
  if (t2 === 0) {
    // console.log("seller approve amount");
    await Token.connect(user2).approve(mainContract.address, sellamount + unit);
  }

  await mainContract.addFund(buyer, buyamount);
  console.log("buyer add");
  await mainContract.addFund(seller, sellamount);
  console.log("seller add");
  console.log("buyer", (await Token.balanceOf(buyer)));
  console.log("seller", (await Token.balanceOf(seller)));
  console.log("contract", (await Token.balanceOf(mainContract.address)));
  console.log("status", (await mainContract.isActive()));




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
