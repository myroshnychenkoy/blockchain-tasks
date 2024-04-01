// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Force} from "../src/Force.sol";
import {AttackForce} from "../src/AttackForce.sol";

contract AttackForceTest is Test {
    Force public force;
    AttackForce public attackForce;

    // Create test addresses
    address ownerForce = makeAddr("ownerForce");
    address ownerAttacker = makeAddr("ownerAttacker");

    function setUp() public {
        vm.prank(ownerForce);
        force = new Force();
        vm.prank(ownerAttacker);
        attackForce = new AttackForce();
    }

    function test_attack() public {
        assertEq(address(force).balance, 0);

        startHoax(ownerAttacker);
        // payable(address(attackForce)).transfer(1 wei);
        // attackForce.attack(address(force));
        // OR
        (bool success, bytes memory data) =
            address(attackForce).call{value: 1 wei}(abi.encodeWithSignature("attack(address)", address(force)));

        assertNotEq(address(force).balance, 0);
    }
}
