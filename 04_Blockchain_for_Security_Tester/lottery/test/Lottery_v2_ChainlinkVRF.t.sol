// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VRFCoordinatorV2Mock} from "chainlink/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

import {DeployLottery} from "../script/DeployLottery.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

import {Lottery} from "../src/Lottery_v2_ChainlinkVRF.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    HelperConfig helperConfig;

    // network config
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;
    uint256 deployerKey;

    // Create test addresses
    // default tx_origin - https://book.getfoundry.sh/reference/config/testing#tx_origin
    address owner = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    address not_owner = makeAddr("not_owner");

    // Create users
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");
    uint256 secret_owner = 4308;
    uint256 secret1 = 1337;

    event WinnerRevealed(address indexed winner, uint256 prizeAmount);

    function setUp() public {
        DeployLottery deployer = new DeployLottery();
        (lottery, helperConfig) = deployer.run();
        vm.pauseGasMetering();
        (entranceFee, interval, vrfCoordinator, keyHash, subscriptionId, callbackGasLimit, link, deployerKey) =
            helperConfig.activeNetworkConfig();
        console.logAddress(lottery.owner());
        vm.resumeGasMetering();
    }

    function setUp_enrollUsers() internal {
        hoax(user1);
        lottery.enroll{value: 5e17}();
        hoax(user2);
        lottery.enroll{value: 5e17}();
        hoax(user3);
        lottery.enroll{value: 5e17}();
        assertEq(lottery.getPlayerCount(), 3);
    }

    function test_adminCantParticipate() public {
        hoax(owner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner));
        vm.breakpoint("a");
        lottery.enroll{value: 5e18}();
    }

    function test_minimumTicketPrice() public {
        hoax(user1);
        vm.expectRevert("Not enough Ether to enroll");
        lottery.enroll{value: 4e17}();
    }

    function test_minimumParticipants() public {
        hoax(user1);
        lottery.enroll{value: 5e17}();

        assertEq(lottery.getPlayerCount(), 1);

        vm.prank(owner);
        vm.expectRevert("Not enough players");
        lottery.lock();
    }

    function test_refund() public {
        setUp_enrollUsers();

        hoax(user1);
        lottery.refund();
        assertEq(lottery.getPlayerCount(), 2);
    }

    function test_unenrolledPlayerCantRefund() public {
        setUp_enrollUsers();

        hoax(user4);
        vm.expectRevert("Player not found");
        lottery.refund();
    }

    function test_onlyAdminCanLock() public {
        vm.prank(not_owner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, not_owner));
        lottery.lock();
    }

    function test_lockable() public {
        setUp_enrollUsers();
        assertEq(lottery.locked(), false);

        vm.prank(owner);
        lottery.lock();
        assertEq(lottery.locked(), true);
    }

    function test_lockCantEnroll() public {
        test_lockable();

        hoax(user4);
        vm.expectRevert("Lottery is locked");
        lottery.enroll{value: 5e17}();
    }

    function test_lockCantRefund() public {
        test_lockable();

        hoax(user1);
        vm.expectRevert("Lottery is locked");
        lottery.refund();
    }

    function test_happyFlow() public {
        setUp_enrollUsers();

        vm.prank(owner);
        vm.recordLogs();
        lottery.lock(); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[0].topics[2]; // RandomWordsRequested -> requestId
        // console.logBytes32(requestId);

        // Pretend to be chainlink VRF to get random number and pick winner
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(lottery));

        vm.prank(user1);
        lottery.revealWinner();

        assertEq(address(lottery).balance, 0);
    }
}
