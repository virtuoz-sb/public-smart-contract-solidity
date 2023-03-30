// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface to retire the Moss on ethereum network
///  Note: https://etherscan.io/address/0x89c4f07d187162fb189b1213aa6fdf42e83b35ec#writeContract

interface IRetireMossOnEthereum {
    /**
     * @dev function to offset carbon foot print on token and inventory.
     * @param _carbonTon Amount to burn on carbon tons.
     * @param _receiptId Transaction identifier that represent the offset.
     * @param _onBehalfOf Broker is burning on behalf of someone.
     */
    function offsetTransaction(
        uint256 _carbonTon,
        string memory _receiptId,
        string memory _onBehalfOf
    ) external;
}
