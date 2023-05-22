// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Task3_Interface.sol";

contract Validator3 {
    address public immutable owner;

    address internal _vault;
    bool internal _attack;
    bool internal _attackStatus;

    constructor() {
        owner = msg.sender;
    }

    function withdrawEther() external {
        require(owner == msg.sender, "Only owner");

        payable(msg.sender).call{value: address(this).balance}("");
    }

    receive() external payable {
        if (_attack) {
            _attack = false;

            (_attackStatus, ) = _vault.call(
                abi.encodeWithSignature("withdrawSafe(address)", address(this))
            );
        }
    }

    function validate(address vault_, address attacker_) external {
        _attack = true;
        _attackStatus = false;
        _vault = vault_;

        Vault(vault_).deposit{value: 0.0001 ether}();

        uint256 vaultBalanceBefore_ = vault_.balance;

        require(
            Vault(vault_).balance(address(this)) == 0.0001 ether,
            "Invalid Validator balance after Vault's deposit"
        );

        // check withdrawSafe
        (bool status_, ) = vault_.call(
            abi.encodeWithSignature("withdrawSafe(address)", address(this))
        );

        require(status_, "withdrawSafe(address) initially reverted");
        require(!_attackStatus, "withdrawSafe(address) is not safe");

        require(
            Vault(vault_).balance(address(this)) == 0,
            "Invalid `Validator` balance after withdrawSafe(address)"
        );
        require(
            vaultBalanceBefore_ - vault_.balance == 0.0001 ether,
            "Invalid `Vault` balance after withdrawSafe(address)"
        );

        // check withdrawUnsafe()
        IAttacker(attacker_).depositToVault{value: 0.0001 ether}(vault_);

        require(
            Vault(vault_).balance(attacker_) == 0.0001 ether,
            "Invalid `Attacker` balance after depositToVault()"
        );
        require(vault_.balance > 0.0001 ether, "Not enough vault balance");

        (status_, ) = attacker_.call(abi.encodeWithSignature("attack(address)", vault_));

        require(status_, "`Attacker` reverted");
        require(vault_.balance == 0, "`Vault` contract balance is not a zero after attack()");
        require(
            Vault(vault_).balance(attacker_) == 0,
            "Invalid vault `Attacker` balance after attack()"
        );
    }
}
