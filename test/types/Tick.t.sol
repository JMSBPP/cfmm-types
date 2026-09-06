// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {PlankTestBase} from "../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";


interface ITick{
    function setTick(int24,uint24) external returns(int24);
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
}
