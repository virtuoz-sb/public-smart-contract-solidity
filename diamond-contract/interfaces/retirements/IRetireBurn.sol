// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRetireBurn {
    function burn(address holder, uint256 amount) external;
}
