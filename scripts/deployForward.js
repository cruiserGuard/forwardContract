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
const flag = true;
if (flag)
{var buyerKey = process.env.BUYER_PRIVATE_KEY;
var sellerKey = process.env.SELLER_PRIVATE_KEY;}

async function main() {
  const [deployer, buyer, seller] = await ethers.getSigners();

  if(flag)
  {buyer.privateKey = buyerKey;
  seller.privateKey = sellerKey;}

  console.log("Deploying contracts with the account:", deployer.address);

  //console.log("Account balance:", (await deployer.getBalance()).toString());

  const mainFactory = await ethers.getContractFactory("forwardUnit");
  console.log("initalization ready");

  const mainContract = await mainFactory.deploy(buyer.address, seller.address, settings.parameters, settings.feeRate);
  await mainContract.deployed();
  const addressETH = settings.parameters.token;
  console.log("token ",addressETH);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  console.log("Forward address:", mainContract.address);
  console.log("amount ", (await mainContract.getContent()).toString());

  const Token = new ethers.Contract(addressETH, WETH9, deployer);
  console.log("buyer", (await Token.balanceOf(buyer.address)));
  console.log("seller", (await Token.balanceOf(seller.address)));
  console.log("contract", (await Token.balanceOf(mainContract.address)));
  // console.log(await Token.totalSupply());
  // console.log(await Token.symbol());
  let buyamount = (await mainContract.buyAmount());
  let sellamount = (await mainContract.sellAmount());
  // let buyamount = (Number(await mainContract.buyAmount())+1).toString();
  // let sellamount = (Number(await mainContract.sellAmount())+1).toString();
  console.log("buyamount ", buyamount);
  console.log("sellamount ", sellamount);
  console.log(typeof  buyamount);
  console.log(Number(buyamount));
  let t1 = (await Token.allowance(buyer.address, mainContract.address)).toNumber();
  if (t1 === 0) {
    console.log("buyer approve amount");
    //console.log((await Token.balanceOf(buyer.address)).toString());
    await Token.connect(buyer).approve(mainContract.address, Number(buyamount) );
    console.log("good");
  }

  let t2 = (await Token.allowance(seller.address, mainContract.address)).toNumber();
  if (t2 === 0) {
    console.log("seller approve amount");
    await Token.connect(seller).approve(mainContract.address, Number(sellamount) );
  }
  console.log(await mainContract.getStatus());
  await mainContract.addFund(buyer.address, Number(buyamount));
  console.log("buyer add");
  console.log(await mainContract.getStatus());
  await mainContract.addFund(seller.address, Number(sellamount));
  console.log("seller add");
  console.log("buyer", (await Token.balanceOf(buyer.address)));
  console.log("seller", (await Token.balanceOf(seller.address)));
  console.log("contract", (await Token.balanceOf(mainContract.address)));
  //console.log("status", (await mainContract.getStatus()));
  console.log(await mainContract.getStatus());
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
