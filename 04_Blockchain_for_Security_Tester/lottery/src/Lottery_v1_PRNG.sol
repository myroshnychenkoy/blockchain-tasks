// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    uint256 public constant LOCK_HOLD_DURATION_BLOCKS = 250;
    uint256 public constant LOCK_HOLD_WINNER_RESELECT_DURATION_BLOCKS = 50;
    uint256 public constant MINIMAL_BET = 5e17; // 0.5 Ether

    uint256 public targetBlockNumber;
    bool public locked; // true if lottery is locked and waiting for winner reveal
    mapping(address => bytes32) public commitments;
    Player[] public players;

    struct Player {
        address payable playerAddress;
        uint256 amount;
    }

    constructor(address initialOwner) Ownable(initialOwner) {
        targetBlockNumber = 0;
        locked = false;
    }

    event PlayerEnrolled(address indexed player, uint256 amount);
    event PlayerRefunded(address indexed player, uint256 amount);
    event LotteryLocked(uint256 targetBlockNumber);
    event WinnerRevealed(address indexed winner, uint256 prizeAmount);

    modifier notOwner() {
        if (owner() == _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
        _;
    }

    function getPlayerCount() public view returns (uint256 count) {
        return players.length;
    }

    function removePlayer(uint256 _index) private {
        uint256 _length = players.length;
        require(_index < _length, "index out of bound");

        // Move the last element to the index of the element to be removed
        players[_index] = players[_length - 1];
        // Remove the last element
        players.pop();
    }

    function enroll(bytes32 commitment) public payable notOwner {
        require(!locked, "Lottery is locked");
        require(msg.value >= MINIMAL_BET, "Not enough Ether to enroll");

        players.push(Player(payable(msg.sender), msg.value));
        commitments[msg.sender] = commitment;

        emit PlayerEnrolled(msg.sender, msg.value);
    }

    function refund() public notOwner {
        // Don't allow refund if lottery is locked, because it can be used to
        // manipulate the winner after target block number is reached
        require(!locked, "Lottery is locked");

        uint256 _length = players.length;
        for (uint256 i = 0; i < _length; i++) {
            if (players[i].playerAddress == msg.sender) {
                emit PlayerRefunded(msg.sender, players[i].amount);
                payable(msg.sender).transfer(players[i].amount);
                removePlayer(i);
                return;
            }
        }
        revert("Player not found");
    }

    function lock(bytes32 ownerCommitment) public onlyOwner {
        require(!locked, "Lottery is already locked");
        require(players.length >= 3, "Not enough players");

        commitments[msg.sender] = ownerCommitment;
        targetBlockNumber = block.number + LOCK_HOLD_DURATION_BLOCKS; // set target block number to use for randomness in winners reveal
        locked = true;

        emit LotteryLocked(targetBlockNumber);
    }

    function revealWinner(uint256 secret) public {
        require(locked, "Lottery is not locked");
        require(block.number > targetBlockNumber, "Target block number not reached");

        uint256 randomN = uint256(blockhash(targetBlockNumber));
        if (randomN == 0) {
            // blockhash is only available for 256 most recent blocks
            // prize was not claimed in time, reselecting the winner
            // This check should be above the commitment check to protect the player from premature secret reveal
            // i.e player can submit invalid secret to trigger new winner selection
            targetBlockNumber = block.number + LOCK_HOLD_WINNER_RESELECT_DURATION_BLOCKS;
            return;
        }

        require(commitments[msg.sender] == keccak256(abi.encodePacked(msg.sender, secret)), "Invalid commitment");

        // pseudorandom relies on two seeds - blockhash of the target block in the future choosed by owner during the lock
        // and secret number provided by the player commited on the enrollment
        // Is it possible to manipulate if miner work together with the player (i.e. secret is known to the miner)?
        randomN = uint256(keccak256(abi.encode(randomN, secret)));

        // 1% of the prize goes to the owner
        payable(owner()).transfer(address(this).balance / 100);

        uint256 index = randomN % players.length;
        uint256 prizeAmount = address(this).balance;
        players[index].playerAddress.transfer(prizeAmount);
        emit WinnerRevealed(players[index].playerAddress, prizeAmount);

        delete players;
        delete targetBlockNumber;
        locked = false;
    }
}
