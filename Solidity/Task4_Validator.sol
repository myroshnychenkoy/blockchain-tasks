// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Task4_Interface.sol";

contract Validator4 {
    function validate(address d_) external returns (bool) {
        A(d_).deposit(10);

        return A(d_).getDeposited() > 0 && C(d_).getC() == 2;
    }
}
