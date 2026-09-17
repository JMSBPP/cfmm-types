// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PlankTestBase} from "../PlankTestBase.sol";


contract RayAlgebraTest is Test ,PlankTestBase{
    address harness;
    function setUp() public {
	harness = deployPlank("src/draft/RayAlgebra.plk");
    }

    function test__halfAndDouble() public {
	(bool ok, bytes memory res) = harness.staticcall("");
	uint256 expectedScaleFactorDown = 0x0000000000000000000000000000000000000000019d971e4fe8401e74000000;
	uint256 scaleFactorDown = abi.decode(res, (uint256));
	assertEq(expectedScaleFactorDown,scaleFactorDown);
	
    }
}
