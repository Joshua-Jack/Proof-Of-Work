// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract MockInitializableContract {
    bool public initialized;

    function initialize() external {
        require(!initialized, "Already initialized");
        initialized = true;
    }
}
