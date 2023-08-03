// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./oracle.sol";
import "./utilis.sol";
import "./interfaces/Math.sol";
//import "hardhat/console.sol";
import "./WETH.sol";

contract forwardUnit {
    // forward contract specification
    contractData private data0;   
    // expire time of forward contract in timestamps
    uint256 private expireTime0;

    // token address (assumed )ERC20 like token)
    address private immutable currency0;
    // address of forward contract buy side
    address private immutable buyer0;
    // address of forward contract sell sides
    address private immutable seller0;

    // operator who create this contract and deliver currency token to proper side, because major gas is paid by operator
    // so operator requires a certain amount token to be compensated
    address private provider0;
    // fee earned by operator(provider0) that is stated in forward contract specification
    uint256 private fee0;
    // current referenceRate
    uint128 public referenceRate0;
    // uint256 public time0;

    bool readybuyer0 = false;        // ready if buyer adds proper fund
    bool readyseller0 = false;       // ready if seller adds proper fund
    bool private active0 = false;   // true if both side add fund and kick off forward contract
    bool private readyFund0 = true; // true if contract is still waiting for adding fund

    // amount that buyer side should deposit in the contract according to margin stated in specification
    uint256 public buyAmount;    
    // amount that seller side should deposit in the contract according to margin stated in specification  
    uint256 public sellAmount;

    // digit for rate of 90-Day ETH APR, address 0x7422A64372f95F172962e2C0f371E0D9531DF276
    uint64 private decimal_rateQ; 

    // event for ready to go
    event Ready(
        address indexed buyer,
        address indexed seller,
        uint32 indexed target,
        uint32 period,
        uint128 NP
    );

    // event for everytime check contract payoff
    event Monitor(
        uint256 indexed time,
        uint256 indexed rate
    );


    constructor(
        address buyer_, 
        address seller_,
        contractData memory data_,
        uint64 feeRateBasis          // fee rate that will pay to operator(provider0)
    ) {
        require(
            buyer_ != address(0) && seller_ != address(0),
            "buyer or seller address is 0"
        );

        currency0 = data_.token;
        expireTime0 = data_.inception; // in definition, the forward's rate inception date is just expire time for forward contract
        buyer0 = payable(buyer_);
        seller0 = payable(seller_);
        provider0 = msg.sender;                 // set operator address to provider0
        
        decimal_rateQ = uint64(10 ** data_.decimal);     // ensure last digit is integer  

        data0 = data_;
        
        // fee0 = NP*feeRateBasis/10000,  feeRateBasis is how many basis point
        uint256 tempdata = data_.NP;
        assembly {
            tempdata := mul(feeRateBasis, div(tempdata, 10000)) 
        }
        fee0 = tempdata;

        sellAmount = calculate(true, data0.upperLimit);
        // upperLimit is defined maximum of sell side deposited fund
        buyAmount = calculate(false, data0.bottomLimit);
        // bottomLiimit is defined maximum of buy side deposited fund
        
    }

    // for buyer side or seller side add fund
    // if both side have added fund, the forward contract is active
    function addFund(address owner, uint128 amount) public payable 
    {
        // ensure buyamount(max amount to pay seller) is large than fee that should pay to operator(provider0). If not, operator cannot get stated compensation
        // that is same logic applied to sellamount
        require(
            buyAmount > fee0 && sellAmount > fee0 ,
            "upperLimit or bottomLimit too low, causing buyAmount or sellAmount insufficient to pay fee"
        );
        // only buyer address or seller address can add fund
        require(
            owner == buyer0 || owner == seller0,
            "the account which deposits fund is neither buyer or seller"
        );

        // because addfund function can kick off forward contract in certain condition. 
        // To avoid improper use addfund function, e.g, forward already go but there is additional fund deposited,
        // readyFund0 can determine if current stage is still funding 
        require(readyFund0,"forward has fund");

        // if it is buyer adding fund when buyer has not funded the contract
        if (owner == buyer0 && (!readybuyer0)) {
            // it need added fund exact equal to buyamount due to making sure liquidation logic correct
            require(
                buyAmount == amount,
                "the required buyAmount is not same as given fund"
            );
            
            // ensure buyer has approve this contract address to transfer WETH
            WETH9(currency0).transferFrom(buyer0, address(this), amount);
            readybuyer0 = true;
        } else if (owner == seller0 && (!readyseller0)) {
            require(
                sellAmount == amount,
                "the required sellAmount is not same as given fund"
            );
            
            WETH9(currency0).transferFrom(seller0, address(this), amount);
            readyseller0 = true;
        }
        // if buyer and seller both deposited correct fund and it is in funding srage, let forward contract active and go
        if (readybuyer0 && readyseller0 && (!active0) && readyFund0) {
            
            active0 = true;
            readyFund0 = false;        
            emit Ready(buyer0, seller0, data0.target, data0.period, data0.NP);
        }
    }

    // change operator(provider0), as operator will get fee in the end of contract, only current operator can call this function
    function changeProvider(address NewProvider) public {
        require(
            msg.sender == provider0,
            "any user who is not provider cannot set new provider "
        );
        provider0 = NewProvider;
    }

    
    // get current forward status, if buyer funded, if sell funded, if contract is active
    function getStatus() public view returns(bool,bool ,bool)
    {
        return (readybuyer0,readyseller0,active0);
    }

    // get contract specification and related account information
    function getContent()
        public
        view
        returns (
            address ,
            address ,
            address ,
            uint256 ,
            uint256 ,
            uint256 ,
            contractData memory
        )
    {
        return (buyer0, seller0, provider0, buyAmount, sellAmount, fee0, data0);
    }

    // according to current reference rate information, calculate payoff of forward contract
    // payBuyer,   1 if True and -1 if False.  The actual code directly reverse sign in calulation
    function payOff(bool payBuyer) internal {
        // check if balance of forward contract has sufficient fund to pay all parties
        require(
            WETH9(currency0).balanceOf(address(this)) >
                buyAmount + sellAmount - fee0,
            "fund is insufficient to payoff"
        );

        // calculate payoff amount according to current reference rate
        uint256 change = calculate(payBuyer, referenceRate0);
        if (payBuyer) {
            // see if payoff amount exceeding sellamount that is maximum available fund to pay buyer
            change = change >= sellAmount ? sellAmount : change;
            // because buyer is winner, so deliver the amount incudes payoff of contract plus buyer deposit
            // Due to that sell side should reduces payoff of contract,and it may cause sell has negtive amount after paying fee 
            // So buyer or winner pay fee only
            WETH9(currency0).transferFrom(
                payable(address(this)),
                buyer0,
                change + buyAmount - fee0
            ); 
            // seller get amount after payoff of contract
            WETH9(currency0).transferFrom(
                payable(address(this)),
                seller0,
                sellAmount - change
            );
        } else {
            // same logic applied to seller win 
            change = change >= buyAmount ? buyAmount : change;
            WETH9(currency0).transferFrom(
                payable(address(this)),
                buyer0,
                buyAmount - change
            );
            WETH9(currency0).transferFrom(
                payable(address(this)),
                seller0,
                change + sellAmount - fee0
            );
        }
    }

    function calculate(
        bool ifPositive,
        uint128 rate
    ) internal view returns (uint256 change) {
        // payoff = NP*((rate - referenceRate)*(period/360))/(1 + (period/360)) * (1) , buyer win
        // payoff = NP*((rate - referenceRate)*(period/360))/(1 + (period/360)) *(-1) , seller win

        // times 2**32 for calculating (period/360)
        uint256 k = uint256(data0.period) << FixedPoint32.RESOLUTION;
        
        assembly {
            k := div(k, 360)
        }

        uint32 temprate = data0.target;
        if (ifPositive) {
            assembly {
                temprate := sub(rate, temprate)
            }
        } else {
            assembly {
                temprate := sub(temprate, rate)
            }
        }

        // denominator and numerator both times 2**32, then in the end divide 2**32
        change =
            (data0.NP *
                (((temprate) * (k << FixedPoint32.RESOLUTION)) /
                    ((decimal_rateQ << FixedPoint32.RESOLUTION) + rate * k))) >>
            FixedPoint32.RESOLUTION;

    }

    // if forward contract is decided to terminate before expire day, operator(provider0) can stop
    function stopButton() public {
        // stop only when forward contract is active and balance of contract is sufficient to pay all parites
        require(
            msg.sender == provider0 && active0 && 
                WETH9(currency0).balanceOf(address(this)) >=
                buyAmount + sellAmount + fee0,"illegal stop forward"
        );
        expireTime0 = block.timestamp + 60; // 1 minute later to trigger stop
    }

    // liquidate contract after payoff
    function liquidate() public
    {
        // contract that has been funded in both parties and inactive goes to end
        // as contract funded by both parties should be exact active. Only after payoff, condition will meet
        require(readybuyer0 && readyseller0 && (!active0),"forward is still active");
        if (provider0 != address(0)) 
        {
            // before end of contract, deliver fee to operator(provider0)
            uint256 balance = address(this).balance;
            WETH9(currency0).transferFrom(
                payable(address(this)),
                provider0,
                balance
            );
            // destruct contract to get GAS or any amount from contract to operator(provider0)
            selfdestruct(payable(provider0)); // alternatve active0 = false;
        }
    }

    // if outcome is current rate is exactly same as reference rate, or payoff of forward contract is 0
    // the contract will refund buyer and seller but subtract fee for operator(provider0)
    function refund() internal
    {
        require(WETH9(currency0).balanceOf(address(this)) >=
                        buyAmount + sellAmount + fee0);
        // for payoff 0 condition, since both sides have sufficient fund, so fee is charged for both sides with each side pays half of fee               
        WETH9(currency0).transferFrom(
            payable(address(this)),
            buyer0,
            buyAmount - fee0 / 2
        ); 
        WETH9(currency0).transferFrom(
            payable(address(this)),
            seller0,
            sellAmount - fee0 / 2
        );
    }

    // monitor rate and see if it is hit payoff
    function monitor(uint current_rate) public {
        require(
            active0 , "forward setting is not ready or it is wrong caller"
        );
        uint current_time = block.timestamp;
        emit Monitor(current_time,current_rate);
        if(
            current_time >= expireTime0 ||
            current_rate >= data0.upperLimit ||
            current_rate <= data0.bottomLimit)
        {
                   
            referenceRate0 = uint128(current_rate);
            
            if (current_rate > data0.target) {
                payOff(true);
                
            } else if (current_rate < data0.target) {
                payOff(false);
                
            }
            
            else {
                refund();          
            }
            active0 = false;
            liquidate();
            
        }
        
    }
}
