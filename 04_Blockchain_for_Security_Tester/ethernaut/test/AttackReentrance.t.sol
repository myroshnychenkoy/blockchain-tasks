// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Reentrance} from "../src/Reentrance.sol";
import {AttackReentrance} from "../src/AttackReentrance.sol";

contract AttackReentranceTest is Test {
    Reentrance public reentrance;
    AttackReentrance public attackReentrance;

    // Create test addresses
    address ownerAttacker = makeAddr("ownerAttacker");

    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    address reentranceAddress = vm.envAddress("SEPOLIA_REENTRANCE_CONTRACT");

    function setUp() public {
        // Solidity v0.8.x has breaking changes in arithmetic operations over/underflows
        // https://docs.soliditylang.org/en/latest/080-breaking-changes.html
        // so let's do the fork-testing instead of locally building the "Reentrancy" contract
        vm.createSelectFork(SEPOLIA_RPC_URL);
        reentrance = Reentrance(payable(reentranceAddress));
        vm.prank(ownerAttacker);
        attackReentrance = new AttackReentrance(address(reentrance));
    }

    function test_attack() public {
        assertEq(address(reentrance).balance, 1000000 gwei);

        hoax(ownerAttacker);
        attackReentrance.attack{value: 100000 gwei}();

        assertEq(address(reentrance).balance, 0);
    }
}
