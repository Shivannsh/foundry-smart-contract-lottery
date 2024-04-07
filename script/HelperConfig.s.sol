// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {CreateSubscription} from "./Interactions.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public ActiveNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            ActiveNetworkConfig = getSepoliaEthConfig();
        } else {
            ActiveNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 30,
            vrfCoordinator: address(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 10774,
            callbackGasLimit: 500000,
            link:address(0x779877A7B0D9E8603169DdbD7836e478b4624789)
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (ActiveNetworkConfig.vrfCoordinator != address(0)) {
            return ActiveNetworkConfig;
        }

        uint96 Base_fee = 0.25 ether;
        uint96 Gas_price_link = 1e9;

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(Base_fee, Gas_price_link);
        LinkToken linktoken = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorV2Mock),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            link: address(linktoken)
        });
    }
}
