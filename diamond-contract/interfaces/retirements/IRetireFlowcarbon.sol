// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @author FlowCarbon LLC
/// @title The common interface of carbon credit tokens
interface IRetireFlowcarbon is IERC20Upgradeable {
    /// @notice Emitted when someone offsets carbon tokens
    /// @param account - The account credited with offsetting
    /// @param amount - The amount of carbon that was offset
    event Offset(address account, uint256 amount);

    /// @notice Offset on behalf of the user
    /// @dev This will only offset tokens send by msg.sender, increases tokens awaiting finalization
    /// @param amount_ - The number of tokens to be offset
    function offset(uint256 amount_) external;

    /// @notice Offsets on behalf of the given address
    /// @dev This will offset tokens on behalf of account, increases tokens awaiting finalization
    /// @param account_ - The address of the account to offset on behalf of
    /// @param amount_ - The number of tokens to be offset
    function offsetOnBehalfOf(address account_, uint256 amount_) external;

    /// @notice Return the balance of tokens offsetted by the given address
    /// @param account_ - The account for which to check the number of tokens that were offset
    /// @return The number of tokens offsetted by the given account
    function offsetBalanceOf(address account_) external view returns (uint256);

    /// @notice Returns the number of offsets for the given address
    /// @dev This is a pattern to discover all offsets and their occurrences for a user
    /// @param address_ - Address of the user that offsetted the tokens
    function offsetCountOf(address address_) external view returns (uint256);

    /// @notice Returns amount of offsetted tokens for the given address and index
    /// @param address_ - Address of the user who did the offsets
    /// @param index_ - Index into the list
    function offsetAmountAtIndex(address address_, uint256 index_) external view returns (uint256);

    /// @notice Returns the timestamp of an offset for the given address and index
    /// @param address_ - Address of the user who did the offsets
    /// @param index_ - Index into the list
    function offsetTimeAtIndex(address address_, uint256 index_) external view returns (uint256);
}
