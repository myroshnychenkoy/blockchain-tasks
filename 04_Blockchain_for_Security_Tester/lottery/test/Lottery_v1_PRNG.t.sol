// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Lottery} from "../src/Lottery_v1_PRNG.sol";

contract LotteryTest is Test {
    Lottery public lottery;

    // Create test addresses
    address owner = makeAddr("owner");
    address not_owner = makeAddr("not_owner");

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");
    uint256 secret_owner = 4308;
    uint256 secret1 = 1337;

    event WinnerRevealed(address indexed winner, uint256 prizeAmount);

    function calcucateCommitment(address _address, uint256 _secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _secret));
    }

    function setUp() public {
        // emit log("Owner address:");
        // emit log_address(owner);
        // console.logAddress(owner);
        vm.prank(owner);
        lottery = new Lottery();
    }

    function setUp_enrollUsers() internal {
        hoax(user1);
        lottery.enroll{value: 5e17}(calcucateCommitment(user1, secret1));
        hoax(user2);
        lottery.enroll{value: 5e17}(calcucateCommitment(user2, secret1));
        hoax(user3);
        lottery.enroll{value: 5e17}(calcucateCommitment(user3, secret1));
        assertEq(lottery.getPlayerCount(), 3);
    }

    function test_adminCantParticipate() public {
        hoax(owner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner));
        vm.breakpoint("a");
        lottery.enroll{value: 5e18}(calcucateCommitment(owner, secret_owner));
    }

    function test_minimumTicketPrice() public {
        hoax(user1);
        vm.expectRevert("Not enough Ether to enroll");
        lottery.enroll{value: 4e17}(calcucateCommitment(user1, secret1));
    }

    function test_minimumParticipants() public {
        hoax(user1);
        lottery.enroll{value: 5e17}(calcucateCommitment(user1, secret1));

        assertEq(lottery.getPlayerCount(), 1);

        vm.prank(owner);
        vm.expectRevert("Not enough players");
        lottery.lock(calcucateCommitment(owner, secret_owner));
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
        lottery.lock(calcucateCommitment(not_owner, secret1));
    }

    function test_lockable() public {
        setUp_enrollUsers();
        assertEq(lottery.locked(), false);

        vm.prank(owner);
        lottery.lock(calcucateCommitment(owner, secret_owner));
        assertEq(lottery.locked(), true);
    }

    function test_lockTargetBlockNumber() public {
        test_lockable();

        assertEq(lottery.targetBlockNumber(), block.number + lottery.LOCK_HOLD_DURATION_BLOCKS());
    }

    function test_lockCantEnroll() public {
        test_lockable();

        hoax(user4);
        vm.expectRevert("Lottery is locked");
        lottery.enroll{value: 5e17}(calcucateCommitment(user4, secret1));
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
        lottery.lock(calcucateCommitment(owner, secret_owner));

        vm.roll(lottery.targetBlockNumber() + 1);
        // uint256 randomN = uint256(keccak256(abi.encode(uint256(blockhash(lottery.targetBlockNumber())), secret1)));
        // uint256 index = randomN % lottery.getPlayerCount();

        vm.prank(user1);
        // vm.expectEmit();
        // emit WinnerRevealed(lottery.players[index].playerAddress);
        lottery.revealWinner(secret1);

        assertEq(address(lottery).balance, 0);
    }
}
