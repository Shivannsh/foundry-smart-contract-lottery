// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";

import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {


    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , ) = helperConfig
            .ActiveNetworkConfig();
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint64) {
        console.log("Creating Subscription on ChainId:", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your SubId is ", subId);
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}
/*-----------------------------------------------------------------------------------------------------------------*/
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*-----------------------------------------------------------------------------------------------------------------*/
contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscription(
        address vrfCoordinator,
        uint64 subId,
        address link
    ) public {
        console.log("Funding Subscription on ChainId:", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
        console.log("Subscription Funded");
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subId,
            ,
            address link
        ) = helperConfig.ActiveNetworkConfig();
        fundSubscription(vrfCoordinator, subId, link);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

/*-----------------------------------------------------------------------------------------------------------------*/
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract AddConsumer is Script{

    function addConsumer(address raffle, address vrfCoordinator, uint64 subId) public{
      console.log("Adding Consumer Contract:" , raffle);
        console.log("Using VRF Coordinator:" , vrfCoordinator);
        console.log("Using Subscription Id:" , subId);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public{
        HelperConfig helperConfig = new HelperConfig();
        (   ,
            ,
            address vrfCoordinator,
            ,
            uint64 subId,
            ,    
        ) = helperConfig.ActiveNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subId);    
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle" , block.chainid);
        addConsumerUsingConfig(raffle);
        }
}