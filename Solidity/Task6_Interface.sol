// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract ArrayStorage {
    uint256[] private array;

    function collide() external virtual;

    function getArray() external view returns (uint256[] memory) {
        return array;
    }
}

contract StorageCollider is ArrayStorage {
    // TODO

    function collide() external override {
        // TODO
    }
}
