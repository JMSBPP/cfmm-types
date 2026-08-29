// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PlankTestBase} from "../../PlankTestBase.sol";
import {VerifyCompliantERC20} from "../../mocks/VerifyCompliantERC20.sol";
import {VerifyBadTransferERC20} from "../../mocks/VerifyBadTransferERC20.sol";
import {VerifyBadAllowanceERC20} from "../../mocks/VerifyBadAllowanceERC20.sol";

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

    function test__unit__compliantErc20Errors_matchOz() public {
        VerifyCompliantERC20 t = new VerifyCompliantERC20();
        (bool ok1, bytes memory d1) = address(t).call(
            abi.encodeWithSelector(VerifyCompliantERC20.transfer.selector, address(this), uint256(1))
        );
        assertFalse(ok1);
        assertEq(bytes4(d1), bytes4(0xe450d38c));

        vm.prank(introspect);
        (bool ok2, bytes memory d2) = address(t).call(
            abi.encodeWithSelector(
                VerifyCompliantERC20.transferFrom.selector, introspect, introspect, uint256(1)
            )
        );
        assertFalse(ok2);
        assertEq(bytes4(d2), bytes4(0xfb8f41b2));
    }

    function test__deploy__verifyErc20_rejectsBadTransfer() public {
        VerifyBadTransferERC20 t0 = new VerifyBadTransferERC20();
        (bool ok,) = introspect.call(
            abi.encodeWithSignature("verifyErc20(address,address)", address(t0), introspect)
        );
        assertFalse(ok, "bad transfer token must fail verify");
    }

    function test__deploy__verifyErc20_rejectsBadAllowance() public {
        VerifyBadAllowanceERC20 t0 = new VerifyBadAllowanceERC20();
        (bool ok,) = introspect.call(
            abi.encodeWithSignature("verifyErc20(address,address)", address(t0), introspect)
        );
        assertFalse(ok, "wrong allowance revert must fail verify");
    }

    function test__deploy__verifyErc20_rejectsEoa() public {
        address eoa = address(0xBEEF);
        (bool ok,) = introspect.call(
            abi.encodeWithSignature("verifyErc20(address,address)", eoa, introspect)
        );
        assertFalse(ok, "EOA must fail balanceOf probe");
    }
}
