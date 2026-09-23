// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {PlankTestBase} from "../PlankTestBase.sol";
import {Test} from "forge-std/Test.sol";

interface IRay {
    function intro(uint256) external returns (uint256);
    function rayMulId() external returns (uint256);
    function rayAddId() external returns (uint256);
    function rayMax() external returns (uint256);
}

contract RayTest is Test, PlankTestBase {
    uint256 internal constant RAY_ZERO = 0;
    uint256 internal constant RAY_UNIT = 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000;
    uint256 internal constant U256_MAX = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
    uint256 internal constant RAY_MAX_VAL = U256_MAX / RAY_UNIT;

    address ray_harness;

    function setUp() public {
        ray_harness = deployPlank("test/harness/RayHarness.plk");
    }

    function test_WhenIntroWrapsX() external {
        // it should return rayVal equal to x
        assertEq(IRay(ray_harness).intro(0), 0);
        assertEq(IRay(ray_harness).intro(RAY_UNIT), RAY_UNIT);
        assertEq(IRay(ray_harness).intro(42), 42);
    }

    function test_WhenRayMulIdIsCalled() external {
        // it should return RAY_UNIT
        assertEq(IRay(ray_harness).rayMulId(), RAY_UNIT);
        assertEq(IRay(ray_harness).rayMulId(), IRay(ray_harness).intro(RAY_UNIT));
    }

    function test_WhenRayAddIdIsCalled() external {
        // it should return RAY_ZERO
        assertEq(IRay(ray_harness).rayAddId(), RAY_ZERO);
        assertEq(IRay(ray_harness).rayAddId(), IRay(ray_harness).intro(RAY_ZERO));
    }

    function test_WhenRayMaxIsCalled() external {
        // it should return floor of U256_MAX over RAY_UNIT
        assertEq(IRay(ray_harness).rayMax(), RAY_MAX_VAL);
        assertEq(IRay(ray_harness).rayMax(), IRay(ray_harness).intro(RAY_MAX_VAL));
    }
}
