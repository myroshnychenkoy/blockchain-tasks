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
    address ownerAttacker = makeAddr("ownerAttacker");

    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    address coinFlipAddress = vm.envAddress("SEPOLIA_COIN_FLIP_CONTRACT");
    uint256 FACTOR = vm.envUint("FACTOR");

    function setUp() public {
        vm.createSelectFork(SEPOLIA_RPC_URL);
        vm.rollFork(block.number - 10);
        coinFlip = CoinFlip(coinFlipAddress);
        vm.prank(ownerAttacker);
        attackCoinFlip = new AttackCoinFlip(coinFlipAddress, FACTOR);
    }

    function test_attack_once_sepolia() public {
        uint256 cw = coinFlip.consecutiveWins();
        hoax(ownerAttacker);
        attackCoinFlip.attack{value: 1e18}();
        assertEq(coinFlip.consecutiveWins(), cw + 1);
    }

    function test_attack_full_sepolia() public {
        for (uint256 i = 0; i < 10; i++) {
            test_attack_once_sepolia();
            vm.rollFork(block.number + 1);
        }
    }
}
