// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 public entranceFee;
    uint256 public interval;
    address public vrfCoordinator;
    bytes32 public gasLane;
    uint64 public subscriptionId;
    uint32 public callbackGasLimit;
    address public link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 100 ether;

    /** EVENTS */
    event EnteredRaffle(address indexed player);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle , helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link
        ) = helperConfig.ActiveNetworkConfig();

        vm.deal(PLAYER, 10 ether);
    }

    ////////////////////////////*/
    /*/enterRaffle        ///*/
    //////////////////////////*/


    function testRaffleInitilizesInOpenState() public {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.5 ether}();
        assert(raffle.getPlayer(0) == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false , address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: 0.2 ether}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.5 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number +1);
        raffle.perfromUpKeep("");

        vm.expectRevert(Raffle.Raffle__WinnerCalculationg.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.5 ether}();
    }

    ////////////////////////////*/
    /*/CheckupKeep    ///*/
    //////////////////////////*/

    function testCheckUpKeepReturnsFalseWhenTimeHasntPassed() public {
        vm.prank(PLAYER);
        vm.roll(block.number +1);
        raffle.enterRaffle{value:0.2 ether}();
        (bool upKeepNeeded,)= raffle.checkUpKeep("");
        assert(upKeepNeeded == false);
    }
    
    function testCheckUpKeepReturnsFalseWhenNotEnoughBalance() public{
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number +1);
        
        (bool upKeepNeeded,) = raffle.checkUpKeep("");
        assert(upKeepNeeded == false);
    }

    function testCheckUpKeepReturnsFalseWhenRaffleCalculating() public{
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.2 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number +1);
        raffle.perfromUpKeep("");

        (bool upKeepNeeded,) = raffle.checkUpKeep("");
        assert(upKeepNeeded == false);
    }

    function testCheckUpKeepReturnsTrueWhenAllParameterrsPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.2 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number +1);
        (bool upKeepNeeded,) = raffle.checkUpKeep("");
        assert(upKeepNeeded == true);
    }

    ////////////////////////////*/
    /*/PerformUpKeep    ///*/
    //////////////////////////*/

    function performUpKeepCanRunOnlyWhenCheckUpKeepisTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.2 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number +1);  
        raffle.perfromUpKeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        raffle.perfromUpKeep("");
    }


}