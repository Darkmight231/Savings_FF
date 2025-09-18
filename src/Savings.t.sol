// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TimeLockSavings} from "src/Savings.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract Savings is Test {
    TimeLockSavings public timeLockSavings;
    MockERC20 token;

    address owner;
    address user1;
    address user2;


    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        owner = makeAddr("owner");

        token = new MockERC20("MockToken", "MTK");

        vm.startPrank(owner);
        timeLockSavings = new TimeLockSavings(address(token));
        vm.stopPrank();
        token.mint(user1, 10000 ether);
        token.mint(user2, 10000 ether);
        
    }

    function test_emergencywithdraw() public{
        // bug works
        vm.startPrank(user1);
        token.approve(address(timeLockSavings), type(uint256).max);
        timeLockSavings.deposit(10 ether);

        vm.startPrank(user1);
        token.approve(address(timeLockSavings), type(uint256).max);
        timeLockSavings.deposit(10 ether);


        vm.startPrank(user2);
        token.approve(address(timeLockSavings), type(uint256).max);
        timeLockSavings.deposit(10 ether);
        vm.stopPrank();

        vm.startPrank(owner);
        timeLockSavings.emergencyWithdraw();

        assertEq(token.balanceOf(address(timeLockSavings)), 0);
        assertEq(token.balanceOf(owner), 3e19);

    }

    function test_deposit() public returns(string memory) {

        while (timeLockSavings.getUserDepositCount(user1) < 1000){
            vm.startPrank(user1);
            token.approve(address(timeLockSavings), type(uint256).max);
            timeLockSavings.deposit(1 ether);
            vm.stopPrank();
        } 
        
        vm.startPrank(user2);
        token.approve(address(timeLockSavings), type(uint256).max);
        timeLockSavings.deposit(1 ether);
        vm.stopPrank();

        if (timeLockSavings.getUserDepositCount(user1) == 1000 && timeLockSavings.getUserDepositCount(user2) >= 1){
            return "Successfully deposited 1000 times && user 2 deposit";
        } else{
            return "Deposit count mismatch";
        }

        
        
    }

    function test_withdraw() public{

        vm.startPrank(user1);
        token.approve(address(timeLockSavings), type(uint256).max);
        timeLockSavings.deposit(1000 ether);

        vm.startPrank(user1);
        token.approve(address(timeLockSavings), type(uint256).max);
        timeLockSavings.deposit(10 ether);


        vm.startPrank(user2);
        token.approve(address(timeLockSavings), type(uint256).max);
        timeLockSavings.deposit(100 ether);

        vm.startPrank(user1);
        // if (token.balanceOf(address(timeLockSavings)) > 0)
        vm.warp(90 days);
        timeLockSavings.withdraw(0);

        vm.startPrank(user2);
        vm.warp(90 days);
        timeLockSavings.withdraw(0);

        assertGt(token.balanceOf(user1), 1000 ether);
        assertLt(token.balanceOf(user2), 100 ether);

    }

    function test_doublewithdrawal() public{

        vm.startPrank(user1);
        token.approve(address(timeLockSavings), type(uint256).max);
        timeLockSavings.deposit(1000 ether);

        vm.startPrank(user1);
        token.approve(address(timeLockSavings), type(uint256).max);
        timeLockSavings.deposit(10 ether);


        vm.startPrank(user2);
        token.approve(address(timeLockSavings), type(uint256).max);
        timeLockSavings.deposit(10000 ether);

        vm.startPrank(user1);
        // if (token.balanceOf(address(timeLockSavings)) > 0)
        vm.warp(90 days);
        timeLockSavings.withdraw(0);

        vm.startPrank(user1);
        vm.warp(90 days);
        timeLockSavings.withdraw(0);

        // assertGt(token.balanceOf(user1), 1000 ether);
        // assertLt(token.balanceOf(user2), 100 ether);
    }
}