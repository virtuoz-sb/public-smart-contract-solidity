// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface to retire the Moss on polygon network
///  Note: https://polygonscan.com/address/0xbca15050f98772e93c95284222f1f5fccc5b6334#code

interface IRetireMossOnPolygon {
    /**
     * @dev Registers a carbon offset operation.
     * @param _carbonTon The amount of carbon to be offset
     * @param _transactionInfo Discricionary info of the carbon offset
     * @param _onBehalfOf in name of whom the offset is executed
     */
    function offsetCarbon(
        uint256 _carbonTon,
        string memory _transactionInfo,
        string memory _onBehalfOf
    ) external;
}
