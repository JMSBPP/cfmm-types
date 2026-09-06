// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {PlankTestBase} from "../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";


interface ITick{
    function setTick(int24,uint24) external returns(int24);
    function max(uint24) external view returns(int256);
    function min(uint24) external view returns(int256);
}


contract TickTest is Test, PlankTestBase {
    address tick_harness;

    function setUp() public {
	tick_harness = deployPlank("test/harness/TickHarness.plk");
    }

    function test__unit__setTick() external {
	int24 tick = int24(-10);
	uint24 ts = uint24(60);
	int24 tickRes = ITick(tick_harness).setTick(tick,ts);
	assertEq(tickRes,-60);
    }

    function test__unit__maxMin() external {
	uint24 ts = uint24(60);
	int256 spacing = int256(uint256(ts));
	int256 expectedMax = int256(uint256(type(uint24).max) / uint256(ts) * uint256(ts));
	int256 loRaw = -int256(uint256(type(uint24).max));
	int256 q = loRaw / spacing;
	if (loRaw % spacing != 0) {
	    q -= 1;
	}
	int256 expectedMin = q * spacing;
	assertEq(ITick(tick_harness).max(ts), expectedMax);
	assertEq(ITick(tick_harness).min(ts), expectedMin);
    }
}
