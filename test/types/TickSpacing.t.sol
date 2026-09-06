// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {PlankTestBase} from "../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";



interface ITickSpacing{}

contract TickSpacingTest is Test, PlankTestBase{
    address tick_spacing_harness;
    function setUp() public {
	tick_spacing_harness = deployPlank("test/harness/TickSpacingHarness.plk");
    }
    function test__placeholder() public{}
}
