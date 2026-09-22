// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PlankTestBase} from "../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";

interface ITimeSpacing {
    function n() external view returns (uint256);
    function dt() external view returns (uint256);
}

contract TimeSpacingTest is Test, PlankTestBase {
    address time_spacing_harness;

    function setUp() public {
        time_spacing_harness = deployPlank("test/harness/TimeSpacingHarness.plk");
    }

    function test__unit__dt2_N_is_WINDOW_div_dt() external view {
        assertEq(ITimeSpacing(time_spacing_harness).dt(), 2);
        assertEq(ITimeSpacing(time_spacing_harness).n(), 43200);
    }
}
