// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Telephone} from "../src/Telephone.sol";
import {AttackTelephone} from "../src/AttackTelephone.sol";

contract AttackTelephoneTest is Test {
    Telephone public telephone;
    AttackTelephone public attackTelephone;

    // Create test addresses
    address ownerTelephone = makeAddr("ownerTelephone");
    address ownerAttacker = makeAddr("ownerAttacker");

    function setUp() public {
        vm.prank(ownerTelephone);
        telephone = new Telephone();
        vm.prank(ownerAttacker);
        attackTelephone = new AttackTelephone(address(telephone));
    }

    function test_attack() public {
        assertEq(telephone.owner(), ownerTelephone);
        vm.prank(ownerAttacker);
        attackTelephone.attack(ownerAttacker);
        assertEq(telephone.owner(), ownerAttacker);
    }
}
