// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {King} from "../src/King.sol";
import {AttackKing} from "../src/AttackKing.sol";

contract AttackKingTest is Test {
    King public king;
    AttackKing public attackKing;

    // Create test addresses
    address ownerKing = makeAddr("ownerKing");
    address ownerAttacker = makeAddr("ownerAttacker");

    function setUp() public {
        hoax(ownerKing);
        king = new King{value: 1000000 gwei}();
        vm.prank(ownerAttacker);
        attackKing = new AttackKing();
    }

    function test_attack() public {
        assertEq(king._king(), ownerKing);

        hoax(ownerAttacker);
        attackKing.attack{value: 1 ether}(address(king));

        vm.expectRevert();
        hoax(ownerKing);
        payable(king).transfer(1 ether);
    }
}
