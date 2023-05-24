// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Task7_Interface.sol";

contract Validator7 {
    bytes signature = hex"500a70b565f66d19c752d0d3f843c4a591562ac92586efd45e616cdb9a8c61d14b7ede082622a139b95cbfca38cfee82a164fad850187c3fe23e08ab268693691c";

    function validate(ValueSetter valueSetter_) external returns (bool) {
        require(valueSetter_.getMessageOwner() == 0x5A902DB2775515E98ff5127EFEa53D1CC9EE1912, "Initial message owner differs from expected");
        require(valueSetter_.getValue() == 0, "Initial value should be 0");

        valueSetter_.setValue(712, signature);

        require(valueSetter_.getValue() == 712, "Value is invalid after setting");

        return true;
    }
}
