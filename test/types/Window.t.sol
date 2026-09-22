// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PlankTestBase} from "../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";

interface IWindow {
    function window() external view returns (uint256);
}

contract WindowTest is Test, PlankTestBase {
    address window_harness;

    function setUp() public {
        window_harness = deployPlank("test/harness/WindowHarness.plk");
    }

    function test__unit__Window_is_Algebra_1_days() external view {
        uint256 w = IWindow(window_harness).window();
        assertEq(w, 86400);
        assertEq(w, 1 days);
        assertEq(w, 0x15180);
    }
}
