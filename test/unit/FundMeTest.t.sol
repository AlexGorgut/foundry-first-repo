// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract FundMeTest is StdCheats, Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_USER_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_USER_BALANCE);
    }

    modifier funded() {
        vm.prank(USER); // The next TX will be sent my USER

        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsaccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWitoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);

        fundMe.cheaperWithdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // c:200
        fundMe.cheaperWithdraw();

        uint256 gasEnd = gasleft(); // 800
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);
        // Assert
        uint256 finishOwnerBalance = fundMe.getOwner().balance;
        uint256 totalBalance = startingFundMeBalance + startingOwnerBalance;
        assertEq(totalBalance, finishOwnerBalance);
        // function testWithdrawFromASingleFunder() public funded {
        //     // Arrange
        //     uint256 startingFundMeBalance = address(fundMe).balance;
        //     uint256 startingOwnerBalance = fundMe.getOwner().balance;

        //     // vm.txGasPrice(GAS_PRICE);
        //     // uint256 gasStart = gasleft();
        //     // // Act
        //     vm.startPrank(fundMe.getOwner());
        //     fundMe.withdraw();
        //     vm.stopPrank();

        //     // uint256 gasEnd = gasleft();
        //     // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        //     // Assert
        //     uint256 endingFundMeBalance = address(fundMe).balance;
        //     uint256 endingOwnerBalance = fundMe.getOwner().balance;
        //     assertEq(endingFundMeBalance, 0);
        //     assertEq(
        //         startingFundMeBalance + startingOwnerBalance,
        //         endingOwnerBalance // + gasUsed
        //     );
        // }
    }

    function testWithDrawWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFudedIndex = 1;

        for (uint160 i = startingFudedIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        uint256 finishOwnerBalance = fundMe.getOwner().balance;
        uint256 totalBalance = startingFundMeBalance + startingOwnerBalance;
        assertEq(totalBalance, finishOwnerBalance);
    }

    // address public constant USER = address(1);

    // // uint256 public constant SEND_VALUE = 1e18;
    // // uint256 public constant SEND_VALUE = 1_000_000_000_000_000_000;
    // // uint256 public constant SEND_VALUE = 1000000000000000000;

    // function setUp() external {
    //     DeployFundMe deployer = new DeployFundMe();
    //     (fundMe, helperConfig) = deployer.run();
    //     vm.deal(USER, STARTING_USER_BALANCE);
    // }

    // function testPriceFeedSetCorrectly() public {
    //     address retreivedPriceFeed = address(fundMe.getPriceFeed());
    //     // (address expectedPriceFeed) = helperConfig.activeNetworkConfig();
    //     address expectedPriceFeed = helperConfig.activeNetworkConfig();
    //     assertEq(retreivedPriceFeed, expectedPriceFeed);
    // }

    // function testFundFailsWithoutEnoughETH() public {
    //     vm.expectRevert();
    //     fundMe.fund();
    // }

    // function testFundUpdatesFundedDataStructure() public {
    //     vm.startPrank(USER);
    //     fundMe.fund{value: SEND_VALUE}();
    //     vm.stopPrank();

    //     uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
    //     assertEq(amountFunded, SEND_VALUE);
    // }

    // function testAddsFunderToArrayOfFunders() public {
    //     vm.startPrank(USER);
    //     fundMe.fund{value: SEND_VALUE}();
    //     vm.stopPrank();

    //     address funder = fundMe.getFunder(0);
    //     assertEq(funder, USER);
    // }

    // // https://twitter.com/PaulRBerg/status/1624763320539525121

    // modifier funded() {
    //     vm.prank(USER);
    //     fundMe.fund{value: SEND_VALUE}();
    //     assert(address(fundMe).balance > 0);
    //     _;
    // }

    // function testOnlyOwnerCanWithdraw() public funded {
    //     vm.expectRevert();
    //     fundMe.withdraw();
    // }

    // function testWithdrawFromASingleFunder() public funded {
    //     // Arrange
    //     uint256 startingFundMeBalance = address(fundMe).balance;
    //     uint256 startingOwnerBalance = fundMe.getOwner().balance;

    //     // vm.txGasPrice(GAS_PRICE);
    //     // uint256 gasStart = gasleft();
    //     // // Act
    //     vm.startPrank(fundMe.getOwner());
    //     fundMe.withdraw();
    //     vm.stopPrank();

    //     // uint256 gasEnd = gasleft();
    //     // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

    //     // Assert
    //     uint256 endingFundMeBalance = address(fundMe).balance;
    //     uint256 endingOwnerBalance = fundMe.getOwner().balance;
    //     assertEq(endingFundMeBalance, 0);
    //     assertEq(
    //         startingFundMeBalance + startingOwnerBalance,
    //         endingOwnerBalance // + gasUsed
    //     );
    // }

    // // Can we do our withdraw function a cheaper way?
    // function testWithDrawFromMultipleFunders() public funded {
    //     uint160 numberOfFunders = 10;
    //     uint160 startingFunderIndex = 2;
    //     for (
    //         uint160 i = startingFunderIndex;
    //         i < numberOfFunders + startingFunderIndex;
    //         i++
    //     ) {
    //         // we get hoax from stdcheats
    //         // prank + deal
    //         hoax(address(i), SEND_VALUE);
    //         fundMe.fund{value: SEND_VALUE}();
    //     }

    //     uint256 startingFundMeBalance = address(fundMe).balance;
    //     uint256 startingOwnerBalance = fundMe.getOwner().balance;

    //     vm.startPrank(fundMe.getOwner());
    //     fundMe.withdraw();
    //     vm.stopPrank();

    //     assert(address(fundMe).balance == 0);
    //     assert(
    //         startingFundMeBalance + startingOwnerBalance ==
    //             fundMe.getOwner().balance
    //     );
    //     assert(
    //         (numberOfFunders + 1) * SEND_VALUE ==
    //             fundMe.getOwner().balance - startingOwnerBalance
    //     );
    // }
}
