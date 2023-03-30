// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRetireToucanNCT {
    function redeemAuto2(uint256 amount) external returns (address[] memory tco2s, uint256[] memory amounts);
}

interface IRetireToucanTCO2 {
    function retire(uint256 amount) external returns (uint256 retirementEventId);
}
