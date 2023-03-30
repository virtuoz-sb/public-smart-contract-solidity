// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRetirementFacet {
    event CarbonTokenRetireSelectorAdded(address token, string name);
    event CarbonTokenRetireSelectorRemoved(address token);
    event Retired(address carbonToken, uint256 amount);

    function retire(address carbonToken, uint256 amount) external;
}
