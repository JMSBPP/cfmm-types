// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @dev Minimal CREATE2 hook donor for hook-miner tests. Validates low 14 bits at deploy time.
contract MinimalHook {
    uint256 public num;

    constructor(uint256 _num, uint16 expectedFlags) {
        num = _num;
        require(
            (uint160(address(this)) & 0x3FFF) == (uint160(expectedFlags) & 0x3FFF),
            "MinimalHook: address flags mismatch"
        );
    }
}
