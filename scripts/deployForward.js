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

const flag = true; // read sepolia accounts instead of test accounts
if (flag)
{var buyerKey = process.env.BUYER_PRIVATE_KEY;
var sellerKey = process.env.SELLER_PRIVATE_KEY;}

function delayTime(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

async function main() {
    const [deployer, buyer, seller] = await ethers.getSigners();

    if(flag)
    {buyer.privateKey = buyerKey;
    seller.privateKey = sellerKey;}

    console.log("Deploying contracts with the account:", deployer.address);

    //console.log("Account balance:", (await deployer.getBalance()).toString());

    const mainFactory = await ethers.getContractFactory("forwardUnit");
    const oracleFactory = await ethers.getContractFactory("chainLinkOracle");
    console.log("initalization ready");

    const mainContract = await mainFactory.deploy(buyer.address, seller.address, settings.parameters, settings.feeRate);
    const oracle = await oracleFactory.deploy(settings.parameters.AddressReferenceRate);
    await mainContract.deployed();
    await oracle.deployed();
    mainContract.on("Ready", (message) => {console.log("Event Ready:", message);});
    mainContract.on("Monitor", (message) => {console.log("Event Monitor:", message);});
    
    const addressETH = settings.parameters.token;
    console.log("token ",addressETH);
    console.log("Account balance:", (await deployer.getBalance()).toString());
    console.log("Forward address:", mainContract.address);
    console.log("oracle address:", oracle.address);
    // console.log("content ", (await mainContract.getContent()).toString());

    const Token = new ethers.Contract(addressETH, WETH9, deployer);
    // console.log("buyer", (await Token.balanceOf(buyer.address)));
    // console.log("seller", (await Token.balanceOf(seller.address)));
    // console.log("contract", (await Token.balanceOf(mainContract.address)));
    // console.log(await Token.totalSupply());
    // console.log(await Token.symbol());
    let buyamount = (await mainContract.buyAmount());
    let sellamount = (await mainContract.sellAmount());
    // let buyamount = (Number(await mainContract.buyAmount())+1).toString();
    // let sellamount = (Number(await mainContract.sellAmount())+1).toString();
    console.log("buyamount ", buyamount);
    console.log("sellamount ", sellamount);
    
    let t1 = await Token.allowance(buyer.address, mainContract.address);
    if (Number(t1) === 0) {
      console.log("buyer approve amount");
      //console.log((await Token.balanceOf(buyer.address)).toString());
      await Token.connect(buyer).approve(mainContract.address, buyamount );
      //await delayTime(1000);
    }

    let t2 = await Token.allowance(seller.address, mainContract.address);
    if (Number(t2) === 0) {
      console.log("seller approve amount");
      await Token.connect(seller).approve(mainContract.address, sellamount );
      //await delayTime(1000);
    }
    console.log(await mainContract.getStatus());
    await mainContract.addFund(buyer.address, buyamount);
    console.log("buyer add");
    await delayTime(15000);
    await mainContract.addFund(seller.address, sellamount);
    console.log("seller add");
    await delayTime(15000);
    console.log("buyer", (await Token.balanceOf(buyer.address)));
    console.log("seller", (await Token.balanceOf(seller.address)));
    console.log("contract", (await Token.balanceOf(mainContract.address)));
    
    st = (await mainContract.getStatus());
    if (st[2]) // if status is active, forward is ready
    {
      console.log("forward ready to go")
    }
    console.log(st);
   
    
    // Writer Contract address to file
    const contractAddressFile = __dirname + "/mainContractAddress.json";
    fs.writeFileSync(
      contractAddressFile,
      JSON.stringify({ address: mainContract.address }, undefined, 2)
    );

    const oracleAddressFile = __dirname + "/oracleAddress.json";
    fs.writeFileSync(
      oracleAddressFile,
      JSON.stringify({ address: oracle.address }, undefined, 2)
    ); 
    
    interval = settings.interval *1000;  // interval for monitor
    
    while(true)
    {
      st = (await mainContract.getStatus());
      if(st[2]==false) break;
      try{
        data = (await oracle.getLatestData());
        console.log("oralce ",data);
        await delayTime(interval);
        await mainContract.monitor(data);
      }
      catch(error){console.log(error);}
      
    }

    try{ await mainContract.liquidate();} // if forward status go to inactive, liquidate contract and refund
    catch(error){console.log(error);}
    
    console.log("forward is completed");
    await delayTime(25000);
    console.log("buyer", (await Token.balanceOf(buyer.address)));   // see if buyer balance meet requirement
    console.log("seller", (await Token.balanceOf(seller.address)));  // see if seller balance meet requirement


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
