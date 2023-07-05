//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {PriceConverter} from "../../src/PriceConverter.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // State Variables
    FundMe fundMe;
    uint256 constant Send_Value = 1 ether;
    uint256 constant Gas_Price = 1;
    // forge cheatcode to create an address, we will use this address as a constant
    // to have this same address as the caller for all functions, for reliability
    address USER = makeAddr("user");

    // setUp() will always run first before each test, it is to deploy contracts and set up test environment
    function setUp() external {
        // deploy the deploy contract to ensure it is working and we are deploying correctly
        // and save the newly deployed FundMe contract that gets deployed by the deploy contract
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        // forge cheatcode to give funds to the newly created address
        vm.deal(USER, 10 ether);
    }

    function testMinUsdIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAcc() public {
        uint256 version = fundMe.getVersion();
        console.log(version);
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next line should revert/fail
        fundMe.fund(); // send 0 value , Min value required is $50, should fail
    }

    modifier funded() {
        vm.startPrank(USER);
        fundMe.fund{value: Send_Value}();
        vm.stopPrank();
        _;
    }

    function testFundSucceedsAndUpdatesMapping() public funded {
        // uses the fund() modifier to have USER call the function and send enough value
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, Send_Value);
    }

    function testFundAddsFunderToArrayOfFunders() public funded {
        // uses funded() modifier to have USER call the function and send enough value
        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.startPrank(USER); // USER will call the withdraw() function

        vm.expectRevert(); // says the next line should revert/
        fundMe.withdraw(); // USER is not the owner cause USER didnt deploy the contract, should fail

        vm.stopPrank();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // .balance is a solidity function that gets the balance of an address
        uint256 startingFundMeBalance = address(fundMe).balance; // balance of fundMe contract after fund() was ran

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // address funder = makeAddr("funder");
            // vm.deal(funder, 10 ether);
            // vm.prank(funder);
            hoax(address(i), Send_Value); // Hoax creates a new address by using "address(index)"
            fundMe.fund{value: Send_Value}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance; // fundMe balance after being funded

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        // Assert
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
        assertEq(endingFundMeBalance, 0);
    }
}
