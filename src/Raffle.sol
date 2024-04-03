// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title Sample Raffle Conntract
 * @author Shivansh Gupta
 * @notice This Contract is for creating sample raffle
 * @dev Implements Chainlink VRFv2
 */

contract Raffle {
    error Raffle__NotEnoughETHSent();

/** State variables */
    uint256 private constant REQUEST_CONFIRMATIONS = 3;
    uint256 private constant NUMWORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    address private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit ;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    /** Events */

    event EnteredRaffle(address indexed player);
    
    constructor(uint256 entranceFee , uint256 interval , address vrfCoordinator , bytes32 gasLane , uint64 subscriptionId , uint32 callbackGasLimit ) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = vrfCoordinator;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);

    }

    function pickWinner() public {
        if((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUMWORDS
        );

    }

    /** Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
