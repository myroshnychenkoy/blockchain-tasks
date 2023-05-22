// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Task5_Interface.sol";

contract Validator5 {
    function validate(StrangeCalculator strangeCalculator_) external returns (bool) {
        uint256 sum = strangeCalculator_.getStorageValuesSum();
        Point memory point_ = strangeCalculator_.getMapValue(12);

        strangeCalculator_.setNewValues(40, Point(21, 22));

        uint256 newSum = strangeCalculator_.getStorageValuesSum();
        Point memory newPoint_ = strangeCalculator_.getMapValue(12);

        require(
            sum != newSum && point_.x != newPoint_.x && point_.y != newPoint_.y,
            "Validator5: values are not changed"
        );

        require(40 == (newSum - 43), "Validator5: one does not changed");

        return true;
    }
}
