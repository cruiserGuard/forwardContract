// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/KeeperCompatibleInterface.sol";
import "./ForwardUnit.sol";

contract chainLinkOracle is KeeperCompatibleInterface {
    AggregatorV3Interface internal dataFeed;

    uint public counter;
    uint public immutable interval;
    uint public lastTimeStamp;
    address immutable forward0;
    address public immutable source;
  
    constructor(address source_,address contract_,uint updateInterval)  
    {
        forward0 = contract_;
        source = source_;
        interval = updateInterval;
        dataFeed = AggregatorV3Interface(source_);
        lastTimeStamp = block.timestamp;
    }


    function getLatestData() internal view returns (int) {
        (
            uint80 roundID, 
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        ) = dataFeed.latestRoundData();
        return answer;
    }

    // function checkUpkeep(bytes calldata /* checkDWata */) view external override returns (bool upkeepNeeded, bytes memory /* performData */) 
    function checkUpkeep(bytes calldata /* checkDWata */) view external override returns (bool upkeepNeeded, bytes memory  ) 
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;

        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        lastTimeStamp = block.timestamp;
        uint currentRate = uint(getLatestData());       
        // forwardUnit(forward0).monitor(lastTimeStamp,currentRate);   // pass
        // (bool success, bytes memory result) = forward0.call("monitor(uint,uint)","lastTimeStamp","currentRate");
        (bool success, bytes memory result) = forward0.call{gas:50000}(abi.encodeWithSignature("monitor(uint,uint)",lastTimeStamp,currentRate)); // pass
        require(success,"call monitor failed");
    }  


}