// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PlankTestBase} from "../../PlankTestBase.sol";
import {VerifyCompliantERC20} from "../../mocks/VerifyCompliantERC20.sol";

contract Erc20IntrospectTest is PlankTestBase {
    address internal introspect;

    function setUp() public {
        introspect = deployPlank("src/lib/token/Erc20Introspect.plk");
    }

    function _verifyErc20(address token) internal {
        (bool ok,) = introspect.call(
            abi.encodeWithSignature("verifyErc20(address,address)", token, introspect)
        );
        require(ok, "verifyErc20 reverted");
    }

    function test__deploy__verifyErc20_acceptsCompliant() public {
        VerifyCompliantERC20 t = new VerifyCompliantERC20();
        _verifyErc20(address(t));
    }
}
