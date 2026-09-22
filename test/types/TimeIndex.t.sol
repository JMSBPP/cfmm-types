// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PlankTestBase} from "../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";

interface ITimeIndex {
    function lastIndex(uint256 tInit, uint256 t) external view returns (uint256);
    function oldestIndex(uint256 tInit, uint256 t) external view returns (uint256);
    function windowStartIndex(uint256 tInit, uint256 t) external view returns (uint256);
    function next(uint256 index) external view returns (uint256);
}

contract TimeIndexTest is Test, PlankTestBase {
    address time_index_harness;
    uint256 constant T_INIT = 1_700_000_000;
    uint256 constant N = 43200;
    uint256 constant M = 65536;
    uint256 constant DT = 2;

    function setUp() public {
        time_index_harness = deployPlank("test/harness/TimeIndexHarness.plk");
    }

    function test__unit__genesis_indices() external view {
        ITimeIndex idx = ITimeIndex(time_index_harness);
        assertEq(idx.lastIndex(T_INIT, T_INIT), 0);
        assertEq(idx.oldestIndex(T_INIT, T_INIT), 0);
        assertEq(idx.windowStartIndex(T_INIT, T_INIT), M - N);
    }

    function test__unit__two_steps_lastIndex() external view {
        assertEq(ITimeIndex(time_index_harness).lastIndex(T_INIT, T_INIT + DT * 2), 2);
    }

    function test__unit__next_wraps_at_M() external view {
        assertEq(ITimeIndex(time_index_harness).next(M - 1), 0);
    }

    function test__unit__clock_wrap_oldestIndex() external view {
        ITimeIndex idx = ITimeIndex(time_index_harness);
        uint256 t = T_INIT + M * DT;
        assertEq(idx.lastIndex(T_INIT, t), 0);
        assertEq(idx.oldestIndex(T_INIT, t), 1);
    }
}
