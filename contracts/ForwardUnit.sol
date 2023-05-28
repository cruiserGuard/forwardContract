// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./oracle.sol";
import "./utilis.sol";
import "./interfaces/Math.sol";
//import "hardhat/console.sol";
import "./WETH.sol";

contract forwardUnit {
    contractData private data0;
    uint256 private expireTime0;
    address private immutable currency0;
    address private immutable buyer0;
    address private immutable seller0;
    address private provider0;
    uint256 private fee0;
    uint128 public referenceRate0;
    // uint256 public time0;

    bool readybuyer0 = false;
    bool readyseller0 = false;
    bool private active0 = false;
    bool private readyFund0 = true;
    uint256 public buyAmount;
    uint256 public sellAmount;

    // address immutable private CHAIN_LINK_ADDRESS; // 0x7422A64372f95F172962e2C0f371E0D9531DF276; // 90-Day ETH APR
    uint64 private decimal_rateQ; // digit for rate of 90-Day ETH APR

    event Ready(
        address indexed buyer,
        address indexed seller,
        uint32 indexed target,
        uint32 period,
        uint128 NP
    );

    event Monitor(
        uint256 indexed time,
        uint256 indexed rate
    );


    constructor(
        address buyer_,
        address seller_,
        contractData memory data_,
        uint64 feeRateBasis
    ) {
        require(
            buyer_ != address(0) && seller_ != address(0),
            "buyer or seller address is 0"
        );

        currency0 = data_.token;
        expireTime0 = data_.inception; // uint(data_.period)* 86400
        buyer0 = payable(buyer_);
        seller0 = payable(seller_);
        provider0 = msg.sender;
        // CHAIN_LINK_ADDRESS = data_.AddressReferenceRate;
        decimal_rateQ = uint64(10 ** data_.decimal);

        data0 = data_;
        // fee0 = feeRateBasis *data_.NP /10000 ;
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

    function addFund(address owner, uint128 amount) public payable 
    {

        require(
            buyAmount > fee0 && sellAmount > fee0 ,
            "upperLimit or bottomLimit too low, causing buyAmount or sellAmount insufficient to pay fee"
        );
        require(
            owner == buyer0 || owner == seller0,
            "the account which deposits fund is neither buyer or seller"
        );

        require(readyFund0,"forward has fund");

        if (owner == buyer0 && (!readybuyer0)) {
            require(
                buyAmount == amount,
                "the required buyAmount is not same as given fund"
            );
            //(bool sucess,) = currency0.call(abi.encodeWithSignature("transferFrom(address,address,uint)",buyer0,address(this),amount) );
            WETH9(currency0).transferFrom(buyer0, address(this), amount);
            readybuyer0 = true;
        } else if (owner == seller0 && (!readyseller0)) {
            require(
                sellAmount == amount,
                "the required sellAmount is not same as given fund"
            );
            //(bool sucess,) = currency0.call(abi.encodeWithSignature("transferFrom(address,address,uint)",seller0,address(this),amount) );
            WETH9(currency0).transferFrom(seller0, address(this), amount);
            readyseller0 = true;
        }
        if (readybuyer0 && readyseller0 && (!active0) && readyFund0) {
            //require(WETH9(currency0).balanceOf(address(this)) >= buyAmount + sellAmount,"fund is mismatch from sum of buyAmount and sellAmount");
            active0 = true;
            readyFund0 = false;
            // chainLinkOracle oracle = new chainLinkOracle(data0.AddressReferenceRate,address(this),10);
            // oracle0 = address(oracle);
            emit Ready(buyer0, seller0, data0.target, data0.period, data0.NP);
        }
    }

    function changeProvider(address NewProvider) public {
        require(
            msg.sender == provider0,
            "any user who is not provider cannot set new provider "
        );
        provider0 = NewProvider;
    }

    // function isActive() public view returns (bool) {
    //     return active0;
    // }

    function getStatus() public view returns(bool,bool ,bool)
    {
        return (readybuyer0,readyseller0,active0);
    }


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

    function payOff(bool payBuyer) internal {
        require(
            WETH9(currency0).balanceOf(address(this)) >
                buyAmount + sellAmount - fee0,
            "fund is insufficient to payoff"
        );

        // bool p = referenceRate0 >= data0.target ? true : false;
        uint256 change = calculate(payBuyer, referenceRate0);
        if (payBuyer) {
            change = change >= sellAmount ? sellAmount : change;
            WETH9(currency0).transferFrom(
                payable(address(this)),
                buyer0,
                change + buyAmount - fee0
            ); // Due to that sell side should reduces change, it may cause sell has negtive amount after less fee. So winner pay fee only
            WETH9(currency0).transferFrom(
                payable(address(this)),
                seller0,
                sellAmount - change
            );
        } else {
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
        uint256 k = uint256(data0.period) << FixedPoint32.RESOLUTION;
        // uint256 k = ((data0.period << FixedPoint32.RESOLUTION)/360);
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

        // if (ifPositive)
        // {

        //     change = data0.NP*(tempdata)*(k << FixedPoint32.RESOLUTION)/((1 << (FixedPoint32.RESOLUTION+decimal_rateQ)) + rate*k) / FixedPoint32.Q32 ;

        // }
        // else
        // {
        //     change = data0.NP*(tempdata)*(k << FixedPoint32.RESOLUTION)/((1 << (FixedPoint32.RESOLUTION+decimal_rateQ)) + rate*k) / FixedPoint32.Q32 ;
        // }
        change =
            (data0.NP *
                (((temprate) * (k << FixedPoint32.RESOLUTION)) /
                    ((decimal_rateQ << FixedPoint32.RESOLUTION) + rate * k))) >>
            FixedPoint32.RESOLUTION;

    }

    function stopButton() public {
        require(
            msg.sender == provider0 && active0 && 
                WETH9(currency0).balanceOf(address(this)) >=
                buyAmount + sellAmount + fee0,"illegal stop forward"
        );
        expireTime0 = block.timestamp + 600; // 10 minute later to trigger stop
    }

    function liquidate() public
    {
        require(readybuyer0 && readyseller0 && (!active0),"forward is still active");
        if (provider0 != address(0)) 
        {
            uint256 balance = address(this).balance;
            WETH9(currency0).transferFrom(
                payable(address(this)),
                provider0,
                balance
            );
            selfdestruct(payable(provider0)); // alternatve active0 = false;
        }
    }

    function refund() internal
    {
        require(WETH9(currency0).balanceOf(address(this)) >=
                        buyAmount + sellAmount + fee0);
        WETH9(currency0).transferFrom(
            payable(address(this)),
            buyer0,
            buyAmount - fee0 / 2
        ); // for netual condition,since both side has sufficient fund, send token back but charge fee for both side
        WETH9(currency0).transferFrom(
            payable(address(this)),
            seller0,
            sellAmount - fee0 / 2
        );
    }

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
            // time0 = current_time;
            if (current_rate > data0.target) {
                payOff(true);
                
            } else if (current_rate < data0.target) {
                payOff(false);
                
            }
            // if current_rate == data0.target
            else {
                refund();          
            }
            active0 = false;
            //liquidate();
            
        }
        
    }
}
