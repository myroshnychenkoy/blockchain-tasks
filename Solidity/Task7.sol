// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract AuthorizedValue {
    uint256 private value;

    address private messageOwner = 0x5A902DB2775515E98ff5127EFEa53D1CC9EE1912;

    function setValueRaw(
        uint256 value_,
        bytes32 messageHash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        address signer = ecrecover(messageHash, v, r, s);

        require(signer == messageOwner, "Invalid signature.");

        value = value_;
    }

    function setValue(uint256 value_, bytes memory signature) external virtual;

    function getValue() external view returns (uint256) {
        return value;
    }

    function getMessageOwner() external view returns (address) {
        return messageOwner;
    }
}

contract ValueSetter is AuthorizedValue {
    function setValue(uint256 value_, bytes memory signature) external override {
        require(signature.length == 65, "Invalid signature length.");  // r (32 bytes) + s (32 bytes) + v (1 byte)
        require(block.chainid == 0xaa36a7, "This contract can only be used on the Sepolia network.");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Split the signature in signature components
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        bytes32 data = keccak256(abi.encode(value_, block.chainid, "ValueSetter"));

        // Craft EIP-191 personal_sign:
        // `0x19 0x45(version byte, but also an "E") <thereum Signed Message:\nlen(msg)> <data to sign>`
        bytes32 messageHash = keccak256(bytes.concat("\x19\x45thereum Signed Message:\n32", data));

        setValueRaw(value_, messageHash, r, s, v);
    }
}
