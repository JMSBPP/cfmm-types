// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {PlankTestBase} from "../../PlankTestBase.sol";
import {MinimalHook} from "../../mocks/MinimalHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-hooks-public/src/utils/HookMiner.sol";

/// @dev Reference: HookMiner with deployer == CREATE2 caller (address(this)).
contract HookMinerSelfDeployerTest is Test {
    function test_solidityHookMiner_selfDeployer() public {
        uint16 flags = uint16(Hooks.BEFORE_SWAP_FLAG);
        bytes memory creationCode = type(MinimalHook).creationCode;
        bytes memory constructorArgs = abi.encode(uint256(42), flags);

        (address predicted, bytes32 salt) =
            HookMiner.find(address(this), flags, creationCode, constructorArgs);

        MinimalHook deployed = new MinimalHook{salt: salt}(42, flags);
        assertEq(address(deployed), predicted);
    }
}

