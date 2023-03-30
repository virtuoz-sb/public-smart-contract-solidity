// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositFacet {
    event Deposited(address depositor, uint256 poolID, address token, uint256 amount);
    event Withdrawn(address depositor, uint256 poolID, address token, uint256 amount);
    event WithdrawnErroneousFund(address depositor, address token, uint256 amount);
    event BalanceUpdated(address depositor, uint256 poolID, address token, uint256 newBalance);
    event FundsUsed(uint256 poolID, address token, uint256 amount);
}
