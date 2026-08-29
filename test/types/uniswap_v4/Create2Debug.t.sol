// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PlankTestBase} from "../../PlankTestBase.sol";
import {MinimalHook} from "../../mocks/MinimalHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-hooks-public/src/utils/HookMiner.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

contract Create2DebugTest is PlankTestBase {
    function test_plankComputeCreate2MatchesSolidity() public {
        address hookMiner = deployPlank("src/types/uniswap_v4/Hook.plk");
        bytes memory creationCode = type(MinimalHook).creationCode;
        bytes memory constructorArgs = abi.encode(uint256(42), uint16(Hooks.BEFORE_SWAP_FLAG));
        bytes memory initCode = abi.encodePacked(creationCode, constructorArgs);
        bytes32 initHash = keccak256(initCode);

        for (uint256 salt = 0; salt < 5; salt++) {
            address sol = HookMiner.computeAddress(hookMiner, salt, initCode);
            address oz = Create2.computeAddress(bytes32(salt), initHash, hookMiner);
            assertEq(sol, oz);

            (bool ok, bytes memory r) = hookMiner.call(
                abi.encodeWithSignature("predictCreate2Address(uint256,uint256)", salt, uint256(initHash))
            );
            require(ok, "predictCreate2Address reverted");
            address plank = address(uint160(uint256(abi.decode(r, (uint256)))));
            assertEq(plank, sol, "create2 address mismatch");
        }
    }
}
