//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
// import {Lottery} from "../src/Lottery.sol";
import {Lottery} from "../src/Lottery_v2_ChainlinkVRF.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployLottery is Script {
    function run() external returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 keyHash,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator, deployerKey);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, link, deployerKey);
        }

        vm.startBroadcast();
        // Lottery lottery = new Lottery(entranceFee, interval, vrfCoordinator, keyHash, subscriptionId, callbackGasLimit);
        Lottery lottery = new Lottery(vrfCoordinator, subscriptionId, keyHash, callbackGasLimit);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(lottery), vrfCoordinator, subscriptionId, deployerKey);

        return (lottery, helperConfig);
    }
}
