# forwardContract
Construct a forward financial contract(FRA) in blockchain

## description
The contract(FRA) involves buyer and seller only and it acts to deliver one party money to another on settlement day. Payoff is according to net present value like traditional FRA does. To solve counterparty default risk, both sides need deposit a certain amount fund in the contract(FRA). The deposited fund acts like margin in futures trading.

## cost
Due to deploy contracts in Ethereum blockchain incurs Gas(cost). And so does applying oracle service from chainlink. The contract will have a role called provider who is responsible for operating contract and also chargeing fee from buyer and seller. 

## oracle service
The contract reads a 90-Day ETH APR from chainLink datafeed. And it is treated benchmark rate. Then it will trigger actions if net present value of FRA reaches threshold or the settlement day. 
