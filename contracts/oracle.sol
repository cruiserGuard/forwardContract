// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/AggregatorV3Interface.sol";
//import "./interfaces/KeeperCompatibleInterface.sol";

//import "./ForwardUnit.sol";

// interface IForwardUnit{
//     function monitor(uint current_time, uint current_rate) external ;
// }

contract chainLinkOracle  {
    AggregatorV3Interface internal dataFeed;

    uint public counter;
    // uint public interval;
    uint public lastTimeStamp;
    address public immutable source;

    //event Trigger(uint time);

    constructor(address source_) {
        source = source_;
        // interval = updateInterval;
        dataFeed = AggregatorV3Interface(source_);
        lastTimeStamp = block.timestamp;
    }

    function getLatestData() public view returns (uint) {
        (
            uint80 roundID,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        ) = dataFeed.latestRoundData();
        return uint(answer);
    }

    // // function checkUpkeep(bytes calldata /* checkDWata */) view external override returns (bool upkeepNeeded, bytes memory /* performData */)
    // function checkUpkeep(
    //     bytes calldata /* checkDWata */
    // ) external view override returns (bool upkeepNeeded, bytes memory) {
    //     upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;

    //     // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    // }

    // function performUpkeep(bytes calldata /* performData default 0x00*/) external override {
    //     lastTimeStamp = block.timestamp;
    //     uint currentRate = uint(getLatestData());
    //     //emit Trigger(1);
    //     IForwardUnit(forward0).monitor(lastTimeStamp,currentRate);   // pass
    //     // (bool success, bytes memory result) = forward0.call("monitor(uint,uint)","lastTimeStamp","currentRate");
    //     // (bool success, bytes memory result) = forward0.call{gas: 50000}(
    //     //     abi.encodeWithSignature(
    //     //         "monitor(uint,uint)",
    //     //         lastTimeStamp,
    //     //         currentRate
    //     //     )
    //     // ); // pass
    //     // require(success, "call monitor failed");
    //     emit Trigger(lastTimeStamp);
    // }
}
