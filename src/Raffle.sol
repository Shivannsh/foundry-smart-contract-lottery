// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title Sample Raffle Conntract
 * @author Shivansh Gupta
 * @notice This Contract is for creating sample raffle
 * @dev Implements Chainlink VRFv2
 */
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughETHSent();
    error Raffle__NotEnoughTimePassed();
    error Raffle__TransferFailed();
    error Raffle__WinnerCalculationg();
    error Raffle__UpKeepNotNeeded(uint256 Curbalance, uint256 Numplayers, uint256 state);

    // Type Declarations
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /**
     * State variables
     */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUMWORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address private immutable i_link;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_RecentWinner;
    RaffleState private s_rafflestate;

    /**
     * Events
     */
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address link
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_rafflestate = RaffleState.OPEN;
        i_link = link;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        if (s_rafflestate != RaffleState.OPEN) {
            revert Raffle__WinnerCalculationg();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function checkUpKeep(bytes memory /*data*/ )
        public
        view
        returns (bool UpKeepNeeded, bytes memory /* perfromData*/ )
    {
        bool timepassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = (RaffleState.OPEN == s_rafflestate);
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        UpKeepNeeded = (timepassed && isOpen && hasBalance && hasPlayers);
        return (UpKeepNeeded, "");
    }

    function perfromUpKeep(bytes memory /* perfromData */ ) external {
        (bool upKeepNeeded,) = checkUpKeep("");

        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(address(this).balance, s_players.length, uint256(s_rafflestate));
        }
        s_rafflestate = RaffleState.CALCULATING;
        uint256 requestId= i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUMWORDS
        );

        emit RequestRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256, /*_requestId */ uint256[] memory _randomWords) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_RecentWinner = winner;
        s_rafflestate = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool Success,) = winner.call{value: address(this).balance}("");
        if (!Success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(winner);
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
    function getRaffleState() external view returns (RaffleState) {
        return s_rafflestate;
    }

    function getNumPlayers() external view returns (address payable[] memory) {
        return s_players;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address payable ){
        return s_players[indexOfPlayer];
    }
}
