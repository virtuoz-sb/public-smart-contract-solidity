// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage, CoolPool} from "../libraries/AppStorage.sol";
import "../libraries/Modifiers.sol";
import "../interfaces/ITriggerFacet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract TriggerFacet is ITriggerFacet, Modifiers {
    // AccessControl Events
    function triggerRoleGranted(
        bytes32 role,
        address account,
        address sender
    ) public {
        emit RoleGranted(role, account, sender);
    }

    function triggerRoleRevoked(
        bytes32 role,
        address account,
        address sender
    ) public {
        emit RoleRevoked(role, account, sender);
    }

    // CentralizedOracle Events
    function triggerSubmitGasUsedCentralized(
        uint256 coolPoolID,
        uint256 gasUsed,
        uint256 lastCalculatedBlock,
        uint256 txCount,
        uint256 timestampTemp
    ) public {
        emit SubmitGasUsedCentralized(coolPoolID, gasUsed, lastCalculatedBlock, txCount, timestampTemp);
    }

    // CoolPool Events
    function triggerPoolCreated(
        uint256 id,
        string memory projectName,
        address creator,
        address greenToken,
        address[] memory accounts,
        string[] memory accountNames,
        uint256 sustainabilityTarget,
        bool offsetPastTxs,
        bool isImmutable
    ) public {
        emit PoolCreated(
            id,
            projectName,
            creator,
            greenToken,
            accounts,
            accountNames,
            sustainabilityTarget,
            offsetPastTxs,
            isImmutable
        );
    }

    function triggerPoolPaused(uint256 poolID, bool isPaused) public {
        emit PoolPaused(poolID, isPaused);
    }

    function triggerMadeImmutable(uint256 poolID) public {
        emit MadeImmutable(poolID);
    }

    function triggerNameUpdated(uint256 poolID, string memory name) public {
        emit NameUpdated(poolID, name);
    }

    function triggerGreenTokenUpdated(uint256 poolID, address greenToken) public {
        emit GreenTokenUpdated(poolID, greenToken);
    }

    function triggerSustainabilityTargetUpdated(uint256 poolID, uint256 target) public {
        emit SustainabilityTargetUpdated(poolID, target);
    }

    function triggerAccountsAdded(
        uint256 poolID,
        address[] memory accounts,
        string[] memory accountNames
    ) public {
        emit AccountsAdded(poolID, accounts, accountNames);
    }

    function triggerAccountsRemoved(uint256 poolID, address[] memory accounts) public {
        emit AccountsRemoved(poolID, accounts);
    }

    function triggerEditorAccessGranted(address[] memory accounts, uint256 poolID) public {
        emit EditorAccessGranted(accounts, poolID);
    }

    function triggerEditorAccessRevoked(address[] memory accounts, uint256 poolID) public {
        emit EditorAccessRevoked(accounts, poolID);
    }

    // Deposit Events
    function triggerDeposited(
        address depositor,
        uint256 poolID,
        address token,
        uint256 amount
    ) public {
        emit Deposited(depositor, poolID, token, amount);
    }

    function triggerWithdrawn(
        address depositor,
        uint256 poolID,
        address token,
        uint256 amount
    ) public {
        emit Withdrawn(depositor, poolID, token, amount);
    }

    function triggerWithdrawnErroneousFund(
        address depositor,
        address token,
        uint256 amount
    ) public {
        emit WithdrawnErroneousFund(depositor, token, amount);
    }

    function triggerBalanceUpdated(
        address depositor,
        uint256 poolID,
        address token,
        uint256 newBalance
    ) public {
        emit BalanceUpdated(depositor, poolID, token, newBalance);
    }

    function triggerFundsUsed(
        uint256 poolID,
        address token,
        uint256 amount
    ) public {
        emit FundsUsed(poolID, token, amount);
    }

    // Retirement Events
    function triggerCarbonTokenRetireSelectorAdded(address token, string memory name) public {
        emit CarbonTokenRetireSelectorAdded(token, name);
    }

    function triggerCarbonTokenRetireSelectorRemoved(address token) public {
        emit CarbonTokenRetireSelectorRemoved(token);
    }

    function triggerRetired(address carbonToken, uint256 amount) public {
        emit Retired(carbonToken, amount);
    }
}
