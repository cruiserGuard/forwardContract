require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-ethers")
//require("@nomiclabs/hardhat-web3")
//require("@nomiclabs/hardhat-truffle5")
require("@nomiclabs/hardhat-etherscan");
//require("hardhat-deploy")
const fs = require("fs");
require('dotenv').config()

const PRIVATE_KEY1 = process.env.WALLET_PRIVATE_KEY1;
const URL1 = process.env.ALCHEMY_URL1;
const PRIVATE_KEY2 = process.env.WALLET_PRIVATE_KEY2;
const URL2 = process.env.ALCHEMY_URL2;
const PRIVATE_KEY3 = process.env.WALLET_PRIVATE_KEY3;
const URL3 = process.env.INFURA_URL1;
const defaultNetwork = 'good';
// console.log(PRIVATE_KEY1);
// console.log(URL1);

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
// task("accounts", "Prints the list of accounts", async () => {
//   const accounts = await ethers.getSigners();

//   for (const account of accounts) {
//     console.log(account.address);
//   }
// });

// function mnemonic() {

//   return process.env.WALLET_PRIVATE_KEY

// }

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {

  defaultNetwork: defaultNetwork,
  networks: {
    hardhat: {
      blockGasLimit: 85000000000,
      allowUnlimitedContractSize: true,
    },
    localhost: {
      url: 'http://127.0.0.1:8545/',
      accounts: ["0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"],
      //gasPrice: 125000000000,  // you can adjust gasPrice locally to see how much it will cost on production
      /*
        run npx hardhat node --port 8545  to get test accounts and put one here
         accounts: ["abcdef0123456789"],
      */
    },
    sepolia: {
      url: URL1,
      accounts: [PRIVATE_KEY1],
    },
    sepolia1: {
      url: URL3,
      accounts: [PRIVATE_KEY3],
    },
    goerli: {
      url: URL2,
      accounts: [PRIVATE_KEY2],
    },
    good: {
      url: "",
      accounts: ["",
        ""],
      gasPrice: 50000000000,
      gas: 5000000,
      blockGasLimit: 1000000000429720,
      // allowUnlimitedContractSize: true,
    },
  },
  // namedAccounts: {
  //   deployer: {
  //     default: 0, // here this will by default take the first account as deployer
  //     1: 0 // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
  //   },
  //   feeCollector: {
  //     default: 1
  //   }
  // },

  solidity: {
    compilers: [
      {
        version: "0.8.0"
      }

    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 888888888888888,
      },
    }
  },
  etherscan: {
    apiKey: "1234"
  },
  mocha: {
    timeout: 6000000000000000
  }

}
//console.log(module.exports.networks);


