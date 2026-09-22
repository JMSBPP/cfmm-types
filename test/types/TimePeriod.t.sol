// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PlankTestBase} from "../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";

interface ITimePeriod {
    function secondsAgo(uint256 k) external view returns (uint256);
    function targetBin(uint256 tInit, uint256 t, uint256 k) external view returns (uint256);
    function twapSecondsAgo(uint256 k) external view returns (uint256);
}

contract TimePeriodTest is Test, PlankTestBase {
    address time_period_harness;
    uint256 constant T_INIT = 1_700_000_000;
    uint256 constant N = 43200;
    uint256 constant M = 65536;
    uint256 constant DT = 2;

    function setUp() public {
        time_period_harness = deployPlank("test/harness/TimePeriodHarness.plk");
    }

    function test__unit__k0_is_now() external view {
        assertEq(ITimePeriod(time_period_harness).secondsAgo(0), 0);
    }

    function test__unit__kN_is_Window() external view {
        assertEq(ITimePeriod(time_period_harness).secondsAgo(N), 86400);
    }

    function test__unit__k_above_N_reverts() external {
        vm.expectRevert();
        ITimePeriod(time_period_harness).secondsAgo(N + 1);
    }

    function test__unit__targetBin_kN_is_windowStart() external view {
        assertEq(
            ITimePeriod(time_period_harness).targetBin(T_INIT, T_INIT, N),
            M - N
        );
    }

    function test__unit__twap_rejects_k0() external {
        vm.expectRevert();
        ITimePeriod(time_period_harness).twapSecondsAgo(0);
    }

    function test__unit__twap_k1_is_dt() external view {
        assertEq(ITimePeriod(time_period_harness).twapSecondsAgo(1), DT);
    }
}
