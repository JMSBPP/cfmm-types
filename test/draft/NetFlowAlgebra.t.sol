// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {console2} from "forge-std/console2.sol";
import {PlankTestBase} from "../PlankTestBase.sol";

contract NetFlowAlgebraTest is Test, PlankTestBase {
    address harness;
    function setUp() public {
	vm.startBroadcast();
	harness = deployPlank("src/draft/NetFlowVariance.plk");
	vm.stopBroadcast();
	
    }

    function test__halfAndDouble() public {
	uint256 blockTimeStamp = vm.getBlockTimestamp();
    /* 	(bool ok, bytes memory res) = harness.staticcall(""); */
    /* 	uint256 expected = 0; */
    /* 	uint256 real = abi.decode(res, (uint256)); */
    /* 	assertEq(expected,real); */
    /* } */
    }
    
}
