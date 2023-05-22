// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IVault {
    function deposit() external payable;

    function withdrawSafe(address payable holder) external;

    function withdrawUnsafe(address payable holder) external;
}

interface IAttacker {
    function depositToVault(address vault) external payable;

    function attack(address vault) external;
}

contract Vault is IVault {
    mapping(address => uint256) public balance;

    function deposit() external payable {
        balance[msg.sender] += msg.value;
    }

    function withdrawSafe(address payable holder) external {
        // TODO
    }

    function withdrawUnsafe(address payable holder) external {
        // TODO
    }
}

contract Attacker is IAttacker {
    function depositToVault(address vault) external payable {
        IVault(vault).deposit{value: msg.value}();
    }

    fallback() external payable {
        // TODO
    }

    function attack(address vault) external {
        // TODO
    }
}
