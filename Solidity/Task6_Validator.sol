// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Task6_Interface.sol";

contract Validator6 {
    function validate(StorageCollider collider_) external returns (bool) {
        require(collider_.getArray().length == 0, "Initial array is not empty");

        collider_.collide();

        uint256[] memory array = collider_.getArray();

        require(array.length > 0, "Array is empty after collision");
        require(array.length > 12, "Array is too small after collision");

        for (uint256 i = 0; i < array.length; i++) {
            require(array[i] > 0, "Array element is zero after collision");
        }

        return true;
    }
}
