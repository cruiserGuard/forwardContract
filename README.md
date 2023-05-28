# forwardContract
Construct a forward financial contract(FRA) in blockchain

## description
The contract(FRA) involves buyer and seller only and it acts to deliver one party money to another on settlement day. Payoff is according to net present value like traditional FRA does. To solve counterparty default risk, both sides need deposit a certain amount fund in the contract(FRA). The deposited fund acts like margin in futures trading.

## cost
Due to deploy contracts in Ethereum blockchain incurs Gas(cost). And so does applying oracle service from chainlink. The contract will have a role called provider who is responsible for operating the contract and also chargeing fees from buyer and seller. 

## oracle service
The contract reads a 90-Day ETH APR from chainLink datafeed. And it is treated benchmark rate. Then it will trigger actions if net present value of FRA reaches threshold or the settlement day. 

## Setup
Proper setup upperLimit, bottomLimit and inception(This is expire day but it is called inception in forward) in scripts/parameters.json .
The forward contract will payoff only when it hit by upperLimit, bottomLimit and time(expires)

## Install hardhat
npm init -y
npx install hardhat

And install required dependencies

## run the contract
npx hardhat run scripts/deployETH.js --network sepolia

This script will deploy WETH token that is treated "money" in this forward contract for payoff
When WETH is deployed, find WETH address in scripts/tokenContractaddress.json
And put this address in parameters.json under the parameters/token.

npx hardhat run scripts/deployForward.js --network sepolia

This script will deploy forward contract and oracle contract, and query data of chainlink 90-Day ETH APR in every 10s.(parameters.json's interval represents it)
