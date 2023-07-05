// SPDX-License-Identifier: MIT

// Fund
// Withdraw

pragma solidity ^0.8.19;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 Send_Value = 0.1 ether;

    function fundFundMe(address mostRecentlyDeployed) public payable {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: Send_Value}();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );

        fundFundMe(mostRecentlyDeployed);
    }
}

contract WithdrawFundMe is Script {
    uint256 Send_Value = 0.01 ether;

    function withdrawFundMe(address mostRecentlyDeployed) public payable {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );

        withdrawFundMe(mostRecentlyDeployed);
    }
}
