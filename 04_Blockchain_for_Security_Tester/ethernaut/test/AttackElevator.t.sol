// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Elevator} from "../src/Elevator.sol";
import {AttackElevator} from "../src/AttackElevator.sol";

contract AttackElevatorTest is Test {
    Elevator public elevator;
    AttackElevator public attackElevator;

    // Create test addresses
    address ownerElevator = makeAddr("ownerElevator");
    address ownerAttacker = makeAddr("ownerAttacker");

    function setUp() public {
        vm.prank(ownerElevator);
        elevator = new Elevator();
        vm.prank(ownerAttacker);
        attackElevator = new AttackElevator();
    }

    function test_attack() public {
        assertEq(elevator.top(), false);

        vm.prank(ownerAttacker);
        attackElevator.attack(address(elevator));

        assertEq(elevator.top(), true);
    }
}
