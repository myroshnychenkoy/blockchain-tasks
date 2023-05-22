// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

struct Point {
    uint256 x;
    uint256 y;
}

contract UintStorage {
    uint256 private one;
    mapping(uint256 => Point) private pointMap;

    constructor() {
        one = 1;
        pointMap[12] = Point(12, 12);
    }

    function setNewValues(uint256 first, Point calldata point) external virtual {}

    function getStorageValuesSum() external view returns (uint256) {
        return one + pointMap[12].x + pointMap[12].y;
    }

    function getMapValue(uint256 key) external view returns (Point memory) {
        return pointMap[key];
    }
}

contract StrangeCalculator is UintStorage {
    function setNewValues(uint256 first, Point calldata point) external override {
        assembly {
            // Change the value of 'one' in the storage
            sstore(0, calldataload(4))   // could be just sstore(0, first)

            // Change the value of 'pointMap[12]' in the storage
            // https://degatchi.com/articles/low_level_guide_to_soliditys_storage_management/
            // The storage slot for mapping 'pointMap[12]' can be calculated as keccak256(mapping_key . mapping_slot)
            mstore(0x00, 0x0c)  // mapping_key - 12
            mstore(0x20, 0x01)  // mapping_slot - 1
            let sslot := keccak256(0x00, 0x40)

            // Access the 'x' and 'y' values from the 'point' struct in calldata
            let x := calldataload(36)   // skip function signature (4 bytes) and the first parameter (32 bytes)
            let y := calldataload(68)

            // Store the 'x' and 'y' values in the 'pointMap[12]' slot
            sstore(sslot, x)
            sstore(add(sslot, 1), y)
        }
    }
}
