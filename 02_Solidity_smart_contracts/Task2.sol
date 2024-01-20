// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Task2_Interface.sol";

contract DataTypesPractice is IDataTypesPractice {
    int256 public int256Val = -42;
    uint256 public uint256Val = 42;
    int8 public int8Val = -42;
    uint8 public uint8Val = 42;
    bool public boolVal = true;
    address public addressVal = 0x4308430843084308430843084308430843084308;
    bytes32 public bytes32Val = 0x4308430843084308430843084308430843084308430843084308430843084308;
    uint256[5] public arrayUint5 = [1, 2, 3, 4, 5];
    uint256[] public arrayUint = [5, 2, 4, 1, 3];
    string public stringVal = "Hello World!";

    function getInt256() external view override returns (int256) {
        return int256Val;
    }

    function getUint256() external view override returns (uint256) {
        return uint256Val;
    }

    function getInt8() external view override returns (int8) {
        return int8Val;
    }

    function getUint8() external view override returns (uint8) {
        return uint8Val;
    }

    function getBool() external view override returns (bool) {
        return boolVal;
    }

    function getAddress() external view override returns (address) {
        return addressVal;
    }

    function getBytes32() external view override returns (bytes32) {
        return bytes32Val;
    }

    function getArrayUint5() external view override returns (uint256[5] memory) {
        return arrayUint5;
    }

    function getArrayUint() external view override returns (uint256[] memory) {
        return arrayUint;
    }

    function getString() external view override returns (string memory) {
        return stringVal;
    }

    function getBigUint() external pure override returns (uint256) {
        uint256 v1 = 1;
        uint256 v2 = 2;
        return ~(v1) - v2;
    }
}