// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Task8_Interface.sol";

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner_) external;
}

contract Validator8 {
    function validate(MyToken token_) external returns (bool) {
        require(
            IOwnable(address(token_)).owner() == address(this),
            "Validator: Validator must be the owner of the token"
        );

        require(_compare(token_.name(), "My Token"), "Validator: Invalid token name");
        require(_compare(token_.symbol(), "MT"), "Validator: Invalid token symbol");
        require(token_.decimals() == 4, "Validator: Invalid token decimals");

        require(
            token_.balanceOf(address(this)) == 0,
            "Validator: Validator must not have any tokens"
        );

        token_.mintTo(address(this), 10000);

        (bool status_, ) = address(token_).call(
            abi.encodeWithSignature("transfer(address,uint256)", address(this), 100)
        );

        require(!status_, "Validator: Invalid transfer logic");

        (status_, ) = address(token_).call(
            abi.encodeWithSignature("transfer(address,uint256)", address(0xdEaD), 100)
        );

        require(status_, "Validator: Invalid transfer logic");

        token_.addToWhitelist(address(this));

        (status_, ) = address(token_).call(
            abi.encodeWithSignature("transfer(address,uint256)", address(this), 100)
        );

        require(status_, "Validator: Invalid transfer logic");

        (status_, ) = address(token_).call(
            abi.encodeWithSignature("transfer(address,uint256)", address(0xdEaD), 100)
        );

        require(status_, "Validator: Invalid transfer logic");

        token_.removeFromWhitelist(address(this));

        (status_, ) = address(token_).call(
            abi.encodeWithSignature("transfer(address,uint256)", address(this), 100)
        );

        require(!status_, "Validator: Invalid transfer logic");

        IOwnable(address(token_)).transferOwnership(msg.sender);

        (status_, ) = address(token_).call(
            abi.encodeWithSignature("addToWhitelist(address)", address(this))
        );

        require(!status_, "Validator: Invalid whitelist logic");

        (status_, ) = address(token_).call(
            abi.encodeWithSignature("removeFromWhitelist(address)", address(this))
        );

        require(!status_, "Validator: Invalid whitelist logic");

        (status_, ) = address(token_).call(
            abi.encodeWithSignature("mintTo(address,uint256)", address(this), 100)
        );

        require(!status_, "Validator: Invalid mint logic");

        return true;
    }

    function _compare(string memory first_, string memory second_) internal pure returns (bool) {
        if (bytes(first_).length != bytes(second_).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(first_)) == keccak256(abi.encodePacked(second_));
        }
    }
}
