// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/StdStyle.sol";
import "forge-std/console.sol";

library Styles {
    function h1(string memory a) public pure returns (string memory) {
        return StdStyle.magenta(StdStyle.underline((StdStyle.bold(a))));
    }

    function h2(string memory a) public pure returns (string memory) {
        return StdStyle.magenta((StdStyle.bold(a)));
    }

    function p(string memory a) public pure returns (string memory) {
        return StdStyle.magenta(StdStyle.italic(a));
    }

    function data(string memory a) public pure returns (string memory) {
        return StdStyle.green(a);
    }
}
