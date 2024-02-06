// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VRFCoordinatorV2Interface} from "chainlink/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "chainlink/v0.8/vrf/VRFConsumerBaseV2.sol";

contract Lottery is Ownable, VRFConsumerBaseV2 {
    event PlayerEnrolled(address indexed player, uint256 amount);
    event PlayerRefunded(address indexed player, uint256 amount);
    event LotteryLocked(uint256 vrfRequestId);
    event WinnerRevealed(address indexed winner, uint256 prizeAmount);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct vrfRequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }

    struct Player {
        address payable playerAddress;
        uint256 amount;
    }

    uint256 public constant LOCK_HOLD_DURATION_BLOCKS = 250;
    uint256 public constant LOCK_HOLD_WINNER_RESELECT_DURATION_BLOCKS = 50;
    uint256 public constant MINIMAL_BET = 5e17; // 0.5 Ether

    // address public constant vrf_COORDINATOR_ADDR = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625; // Sepolia
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 constant vrf_keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c; // Sepolia, 150 gwei Key Hash
    uint16 constant vrf_requestConfirmations = 5;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas.
    // Test and adjust this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords() function.
    uint32 vrf_callbackGasLimit = 40000;
    vrfRequestStatus public vrf_requestStatus;
    uint256 public vrf_lastRequestId;

    bool public locked; // true if lottery is locked and waiting for winner reveal
    Player[] public players;

    VRFCoordinatorV2Interface vrf_COORDINATOR;
    uint64 vrf_subscriptionId;

    constructor(address vrfCoordinator, uint64 vrfSubscriptionId)
        Ownable(msg.sender)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        locked = false;
        vrf_COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        vrf_subscriptionId = vrfSubscriptionId;
    }

    modifier notOwner() {
        if (owner() == _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
        _;
    }

    function getPlayerCount() public view returns (uint256 count) {
        return players.length;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(vrf_lastRequestId == requestId, "VRF request not found");
        vrf_requestStatus.fulfilled = true;
        vrf_requestStatus.randomWords = randomWords;
        emit RequestFulfilled(requestId, randomWords);
    }

    function removePlayer(uint256 _index) private {
        uint256 _length = players.length;
        require(_index < _length, "index out of bound");

        // Move the last element to the index of the element to be removed
        players[_index] = players[_length - 1];
        // Remove the last element
        players.pop();
    }

    function enroll() public payable notOwner {
        require(!locked, "Lottery is locked");
        require(msg.value >= MINIMAL_BET, "Not enough Ether to enroll");

        players.push(Player(payable(msg.sender), msg.value));

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

    function lock() public onlyOwner returns (uint256 vrfRequestId) {
        require(!locked, "Lottery is already locked");
        require(players.length >= 3, "Not enough players");

        // Will revert if subscription is not set and funded.
        vrfRequestId = vrf_COORDINATOR.requestRandomWords(
            vrf_keyHash,
            vrf_subscriptionId,
            vrf_requestConfirmations,
            vrf_callbackGasLimit,
            1 // numWords
        );
        vrf_requestStatus = vrfRequestStatus({randomWords: new uint256[](0), fulfilled: false});
        vrf_lastRequestId = vrfRequestId;
        locked = true;
        emit LotteryLocked(vrfRequestId);

        return vrfRequestId;
    }

    function revealWinner() public {
        require(locked, "Lottery is not locked");
        require(vrf_requestStatus.fulfilled == true, "VRF request not fulfilled");

        // 1% of the prize goes to the owner
        payable(owner()).transfer(address(this).balance / 100);

        uint256 index = vrf_requestStatus.randomWords[0] % players.length;
        uint256 prizeAmount = address(this).balance;
        players[index].playerAddress.transfer(prizeAmount);
        emit WinnerRevealed(players[index].playerAddress, prizeAmount);

        delete players;
        delete vrf_requestStatus;
        locked = false;
    }
}
