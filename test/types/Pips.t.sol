// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {PlankTestBase} from "../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";

interface IPips {
    function intro(uint256, uint256) external returns (uint16);
}

contract PipsTest is Test, PlankTestBase {
    uint256 internal constant PIPS = 1_000_000;

    address pips_harness;

    function setUp() public {
        pips_harness = deployPlank("test/harness/PipsHarness.plk");
    }

    function test_WhenMulDivFitsU16() external {
        // it should return Pips val equal to floor of v1 times v2 over PIPS
        uint16 got = IPips(pips_harness).intro(PIPS, 42);
        assertEq(got, 42);

        uint16 maxOk = IPips(pips_harness).intro(65535 * PIPS, 1);
        assertEq(maxOk, 65535);
    }

    function test_RevertWhen_MulDivExceedsU16Max() external {
        // it should revert
        vm.expectRevert();
        IPips(pips_harness).intro(65536 * PIPS, 1);
    }
}
