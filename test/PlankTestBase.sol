// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {PlankDeployer, BuildOptions, Dependency} from "plank-foundry-deployer/PlankDeployer.sol";

/// @dev Keep module roots in sync with Makefile:PLANK_DEP.
abstract contract PlankTestBase is Test, PlankDeployer {
    function plankOpts() internal pure returns (BuildOptions memory opts) {
        opts.backend = "sona";
        Dependency[] memory deps = new Dependency[](3);
        deps[0] = Dependency("std", "lib/plank-monorepo/std/");
        deps[1] = Dependency("types", "src/types");
        deps[2] = Dependency("lib", "src/lib");
        opts.dependencies = deps;
    }

    function deployPlank(string memory path) internal returns (address) {
        return plankDeployFFI(path, plankOpts());
    }
}
