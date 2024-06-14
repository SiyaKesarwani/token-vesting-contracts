// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/TokenVesting.sol";
import "../../src/Token.sol";

contract TokenVestingTest is Test {
    Token public token;
    TokenVesting public tokenVesting;

    function setUp() public {
        token = new Token("Test Token", "TT", 1000000);
        tokenVesting = new TokenVesting(address(token));
    }

    // TODO: add tests
    function testCreateVestingSchedule() public {
        // send tokens to vesting contract so that users get some extra tokens at the end of vesting
        token.transfer(address(tokenVesting), 10000);
        // check the transfer
        assertEq(token.balanceOf(address(tokenVesting)), 10000);
        assertEq(tokenVesting.getWithdrawableAmount(), 10000);

        // Now check the given condition
        address beneficiary = address(this);
        uint256 start = block.timestamp;
        uint256 cliff = 7889400; // 3 months
        uint256 duration = 26298000; // 10 months
        uint256 slicePeriodSeconds = 1; // amount changes at every 1 sec
        bool revocable = true;
        uint256 amount = 1000; // 1000 tokens

        tokenVesting.createVestingSchedule(
            beneficiary, 
            start, 
            cliff, 
            duration, 
            slicePeriodSeconds, 
            revocable, 
            amount
        );

        assertEq(tokenVesting.getVestingSchedulesCount(), 1);
        assertEq(tokenVesting.getVestingSchedulesCountByBeneficiary(beneficiary), 1);
        bytes32 vestingScheduleId = tokenVesting.computeVestingScheduleIdForAddressAndIndex(beneficiary, 0);

        // Check the vested amount instantly
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), 0);

        // Check vested amount before the end of cliff period
        vm.warp(block.timestamp + cliff - 1);
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), 0);

        // Check vested amount after cliff period
        vm.warp(block.timestamp + 1);
        assertEq(tokenVesting.computeReleasableAmount(vestingScheduleId), 300);
    }
}
