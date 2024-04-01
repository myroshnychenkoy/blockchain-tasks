// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {GatekeeperTwo} from "../src/GatekeeperTwo.sol";
import {AttackGatekeeperTwo} from "../src/AttackGatekeeperTwo.sol";

contract AttackGatekeeperTwoTest is Test {
    GatekeeperTwo public gatekeeperTwo;
    AttackGatekeeperTwo public attackGatekeeperTwo;

    // Create test addresses
    address ownerGatekeeperTwo = makeAddr("ownerGatekeeperTwo");
    address ownerAttacker = makeAddr("ownerAttacker");

    function setUp() public {
        vm.prank(ownerGatekeeperTwo);
        gatekeeperTwo = new GatekeeperTwo();
    }

    function test_attack() public {
        assertNotEq(gatekeeperTwo.entrant(), tx.origin);

        vm.prank(ownerAttacker);
        attackGatekeeperTwo = new AttackGatekeeperTwo(address(gatekeeperTwo));

        assertEq(gatekeeperTwo.entrant(), tx.origin);
    }
}
