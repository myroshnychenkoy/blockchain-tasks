// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CoinFlip} from "../src/CoinFlip.sol";
import {AttackCoinFlip} from "../src/AttackCoinFlip.sol";

contract AttackCoinFlipTest is Test {
    CoinFlip public coinFlip;
    AttackCoinFlip public attackCoinFlip;

    // Create test addresses
    address ownerCoinFlip = makeAddr("ownerCoinFlip");
    address ownerAttacker = makeAddr("ownerAttacker");

    uint256 FACTOR = vm.envUint("FACTOR");

    function setUp() public {
        vm.prank(ownerCoinFlip);
        coinFlip = new CoinFlip();
        vm.prank(ownerAttacker);
        attackCoinFlip = new AttackCoinFlip(address(coinFlip), FACTOR);
    }

    function test_attack_once() public {
        uint256 cw = coinFlip.consecutiveWins();
        hoax(ownerAttacker);
        attackCoinFlip.attack{value: 1e18}();
        assertEq(coinFlip.consecutiveWins(), cw + 1);
    }

    function test_attack_twice() public {
        test_attack_once();
        hoax(ownerAttacker);
        vm.expectRevert("Already flipped. Wait for next block.");
        attackCoinFlip.attack{value: 1e18}();
    }

    function test_finish() public {
        hoax(ownerAttacker);
        attackCoinFlip.finish();
        assertEq(address(attackCoinFlip).balance, 0);
    }
}
