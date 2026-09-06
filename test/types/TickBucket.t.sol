// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PlankTestBase} from "../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";

interface ITickBucket {
    function tickBucket(uint24) external view returns (int256, int256);
}

contract TickBucketTest is Test, PlankTestBase {
    address tick_bucket_harness;

    function setUp() public {
        tick_bucket_harness = deployPlank("test/harness/TickBucketHarness.plk");
    }

    function test__unit__tickBucket_fromSpacing() external view {
        uint24 ts = uint24(60);
        (int256 lo, int256 hi) = ITickBucket(tick_bucket_harness).tickBucket(ts);

        int256 spacing = int256(uint256(ts));
        int256 expectedMax = int256(uint256(type(uint24).max) / uint256(ts) * uint256(ts));
        int256 loRaw = -int256(uint256(type(uint24).max));
        int256 q = loRaw / spacing;
        if (loRaw % spacing != 0) {
            q -= 1;
        }
        int256 expectedMin = q * spacing;

        assertEq(lo, expectedMin);
        assertEq(hi, expectedMax);
    }
}
