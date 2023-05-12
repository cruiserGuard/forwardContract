# forwardContract
construct a forward financial contract(FRA) in blockchain


## oracle service
The contract reads a 90-Day ETH APR from chainLink datafeed. And it is treated benchmark rate. Then it will trigger actions if net present value of FRA reaches threshold or the settlement day. 
