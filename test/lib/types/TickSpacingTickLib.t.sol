// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PlankTestBase} from "../../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";

interface ITickSpacingTickLib {}

contract TickSpacingTickLibTest is Test, PlankTestBase {
    address tick_spacing_tick_lib_harness;

    function setUp() public {
        tick_spacing_tick_lib_harness =
            deployPlank("test/harness/lib/TickSpacingTickLibHarness.plk");
    }
}
