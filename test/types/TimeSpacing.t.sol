// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PlankTestBase} from "../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";

interface ITimeSpacing {
    function n() external view returns (uint256);
    function dt() external view returns (uint256);
    function sqrtDt2() external returns (uint256);
    function sqrtDt3() external returns (uint256);
    function sqrtDt4() external returns (uint256);
    function sqrtDt5() external returns (uint256);
    function sqrtDt6() external returns (uint256);
    function sqrtDt8() external returns (uint256);
    function sqrtDt9() external returns (uint256);
    function sqrtDt10() external returns (uint256);
}

contract TimeSpacingTest is Test, PlankTestBase {
    uint256 internal constant SQRT_DT_RAY_2 = 1414213562373095048801688724;
    uint256 internal constant SQRT_DT_RAY_3 = 1732050807568877293527446341;
    uint256 internal constant SQRT_DT_RAY_4 = 2000000000000000000000000000;
    uint256 internal constant SQRT_DT_RAY_5 = 2236067977499789696409173668;
    uint256 internal constant SQRT_DT_RAY_6 = 2449489742783178098197284074;
    uint256 internal constant SQRT_DT_RAY_8 = 2828427124746190097603377448;
    uint256 internal constant SQRT_DT_RAY_9 = 3000000000000000000000000000;
    uint256 internal constant SQRT_DT_RAY_10 = 3162277660168379331998893544;

    address time_spacing_harness;

    function setUp() public {
        time_spacing_harness = deployPlank("test/harness/TimeSpacingHarness.plk");
    }

    function test__unit__dt2_N_is_WINDOW_div_dt() external view {
        assertEq(ITimeSpacing(time_spacing_harness).dt(), 2);
        assertEq(ITimeSpacing(time_spacing_harness).n(), 43200);
    }

    function test_WhenDtIs2() external {
        // it should return SQRT_DT_RAY_2
        assertEq(ITimeSpacing(time_spacing_harness).sqrtDt2(), SQRT_DT_RAY_2);
    }

    function test_WhenDtIs3() external {
        // it should return SQRT_DT_RAY_3
        assertEq(ITimeSpacing(time_spacing_harness).sqrtDt3(), SQRT_DT_RAY_3);
    }

    function test_WhenDtIs4() external {
        // it should return SQRT_DT_RAY_4
        assertEq(ITimeSpacing(time_spacing_harness).sqrtDt4(), SQRT_DT_RAY_4);
    }

    function test_WhenDtIs5() external {
        // it should return SQRT_DT_RAY_5
        assertEq(ITimeSpacing(time_spacing_harness).sqrtDt5(), SQRT_DT_RAY_5);
    }

    function test_WhenDtIs6() external {
        // it should return SQRT_DT_RAY_6
        assertEq(ITimeSpacing(time_spacing_harness).sqrtDt6(), SQRT_DT_RAY_6);
    }

    function test_WhenDtIs8() external {
        // it should return SQRT_DT_RAY_8
        assertEq(ITimeSpacing(time_spacing_harness).sqrtDt8(), SQRT_DT_RAY_8);
    }

    function test_WhenDtIs9() external {
        // it should return SQRT_DT_RAY_9
        assertEq(ITimeSpacing(time_spacing_harness).sqrtDt9(), SQRT_DT_RAY_9);
    }

    function test_WhenDtIs10() external {
        // it should return SQRT_DT_RAY_10
        assertEq(ITimeSpacing(time_spacing_harness).sqrtDt10(), SQRT_DT_RAY_10);
    }
}
