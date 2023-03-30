// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/AppStorage.sol";
import {IDepositFacet} from "../interfaces/IDepositFacet.sol";
import "../libraries/Modifiers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

contract DepositFacet is IDepositFacet, Modifiers {
    /**
     * Each time some amount of funds are used, we increase the period by 1.
     * Total deposit amount at that moment is also saved with the previous period.
     * While calculating users' shares for funds used, we divide user's balance by total deposit at that period to get their ratio.
     * This means each user in a period is treated equally.
     */

    modifier tokenAllowed(address token) {
        require(s.carbonTokenToRetireSelector[token] != bytes4(0), "Modifiers: Token is not allowed!");
        _;
    }

    bytes32 private constant DEPOSIT_ADMIN_ROLE = keccak256("DEPOSIT_ADMIN_ROLE");

    function deposit(
        address token,
        uint256 amount,
        uint256 poolID
    ) public tokenAllowed(token) systemUnpaused coolPoolUnpaused(poolID) {
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        updateBalance(poolID, token, msg.sender);

        s.coolPools[poolID].poolInfos[token].depositors[msg.sender].balance += amount;
        s.coolPools[poolID].poolInfos[token].currentTotalDeposit += amount;

        emit Deposited(msg.sender, poolID, token, amount);
    }

    function withdraw(
        address token,
        uint256 amount,
        uint256 poolID
    ) public systemUnpaused {
        uint256 userBalance = updateBalance(poolID, token, msg.sender);

        amount = amount > userBalance ? userBalance : amount;

        s.coolPools[poolID].poolInfos[token].depositors[msg.sender].balance -= amount;
        s.coolPools[poolID].poolInfos[token].currentTotalDeposit -= amount;

        IERC20(token).transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, poolID, token, amount);
    }

    function updateBalance(
        uint256 poolID,
        address token,
        address user
    ) internal systemUnpaused returns (uint256 newBalance) {
        s.coolPools[poolID].poolInfos[token].depositors[user].balance = availableBalance(poolID, token, user);
        s.coolPools[poolID].poolInfos[token].depositors[user].lastDepositPeriod = s
            .coolPools[poolID]
            .currentDepositPeriod;

        newBalance = s.coolPools[poolID].poolInfos[token].depositors[user].balance;

        emit BalanceUpdated(user, poolID, token, newBalance);
    }

    function availableBalance(
        uint256 poolID,
        address token,
        address user
    ) public view returns (uint256 balance) {
        uint256 lastDepositPeriod = s.coolPools[poolID].poolInfos[token].depositors[user].lastDepositPeriod;
        uint256 currentPeriod = s.coolPools[poolID].currentDepositPeriod;

        uint256 userShare;
        uint256 userBalance = s.coolPools[poolID].poolInfos[token].depositors[user].balance;
        for (uint256 i = lastDepositPeriod; i < currentPeriod; i++) {
            uint256 usedAmount = s.coolPools[poolID].poolInfos[token].periodInfos[i].usedAmount;
            uint256 totalDeposit = s.coolPools[poolID].poolInfos[token].periodInfos[i].latestTotalDeposit;

            uint256 currentShare = (userBalance * usedAmount) / totalDeposit;

            userShare += currentShare;
            userBalance -= currentShare;
        }

        balance = s.coolPools[poolID].poolInfos[token].depositors[user].balance - userShare;
    }

    function useFunds(
        uint256 poolID,
        address token,
        uint256 amount
    ) public onlyRole(DEPOSIT_ADMIN_ROLE) systemUnpaused coolPoolUnpaused(poolID) {
        // TODO: better error handling on insufficient funds
        uint256 currentPeriod = s.coolPools[poolID].currentDepositPeriod++;

        /**
         * We save used amount and total deposit for current period. This info is used later for calculating users' shares for each period
         */
        s.coolPools[poolID].poolInfos[token].periodInfos[currentPeriod].latestTotalDeposit = s
            .coolPools[poolID]
            .poolInfos[token]
            .currentTotalDeposit;
        s.coolPools[poolID].poolInfos[token].periodInfos[currentPeriod].usedAmount = amount;
        s.coolPools[poolID].poolInfos[token].currentTotalDeposit -= amount;

        emit FundsUsed(poolID, token, amount);
    }

    function getUserBalance(
        address user,
        uint256 poolID,
        address token
    ) public view returns (uint256) {
        return availableBalance(poolID, token, user);
    }

    function getTotalDeposit(uint256 poolID, address token) public view returns (uint256) {
        return s.coolPools[poolID].poolInfos[token].currentTotalDeposit;
    }

    function getPeriodInfo(
        uint256 poolID,
        address token,
        uint256 period
    ) public view returns (uint256, uint256) {
        return (
            s.coolPools[poolID].poolInfos[token].periodInfos[period].latestTotalDeposit,
            s.coolPools[poolID].poolInfos[token].periodInfos[period].usedAmount
        );
    }

    function withdrawErroneousFund(address token, uint256 amount) public onlyRole(DEPOSIT_ADMIN_ROLE) systemUnpaused {
        /* This function is dangerous!
         * When a token is disallowed and admin withdraws with this,
         * they can withdraw the whole funds &
         * that token cannot be added again because of broken state.
         */
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            require(s.carbonTokenToRetireSelector[token] == bytes4(0), "Modifiers: Token is still depositable!");
            IERC20(token).transfer(msg.sender, amount);
        }

        emit WithdrawnErroneousFund(msg.sender, token, amount);
    }
}
