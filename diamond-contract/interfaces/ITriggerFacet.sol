// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITriggerFacet {
    // AccessControl Events
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // CentralizedOracle Events
    event SubmitGasUsedCentralized(
        uint256 coolPoolID,
        uint256 gasUsed,
        uint256 lastCalculatedBlock,
        uint256 txCount,
        uint256 timestampTemp
    );

    // CoolPool Events
    event PoolCreated(
        uint256 id,
        string projectName,
        address creator,
        address greenToken,
        address[] accounts,
        string[] accountNames,
        uint256 sustainabilityTarget,
        bool offsetPastTxs,
        bool isImmutable
    );
    event PoolPaused(uint256 poolID, bool isPaused);

    event MadeImmutable(uint256 poolID);
    event NameUpdated(uint256 poolID, string name);
    event GreenTokenUpdated(uint256 poolID, address greenToken);
    event SustainabilityTargetUpdated(uint256 poolID, uint256 target);

    event AccountsAdded(uint256 poolID, address[] accounts, string[] accountNames);
    event AccountsRemoved(uint256 poolID, address[] accounts);

    event EditorAccessGranted(address[] accounts, uint256 poolID);
    event EditorAccessRevoked(address[] accounts, uint256 poolID);

    // Deposit Events
    event Deposited(address depositor, uint256 poolID, address token, uint256 amount);
    event Withdrawn(address depositor, uint256 poolID, address token, uint256 amount);
    event WithdrawnErroneousFund(address depositor, address token, uint256 amount);
    event BalanceUpdated(address depositor, uint256 poolID, address token, uint256 newBalance);
    event FundsUsed(uint256 poolID, address token, uint256 amount);

    // Retirement Events
    event CarbonTokenRetireSelectorAdded(address token, string name);
    event CarbonTokenRetireSelectorRemoved(address token);
    event Retired(address carbonToken, uint256 amount);
}
