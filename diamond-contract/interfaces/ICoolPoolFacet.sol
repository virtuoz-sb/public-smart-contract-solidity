// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoolPoolFacet {
    event PoolCreated(
        uint256 id,
        string projectName,
        address creator,
        address greenToken,
        address[] accounts,
        string[] accountNames,
        uint64 sustainabilityTargetPercent,
        bool offsetPastTxs,
        bool isImmutable
    );
    event PoolPaused(uint256 poolID, bool isPaused);

    event MadeImmutable(uint256 poolID);
    event NameUpdated(uint256 poolID, string name);
    event GreenTokenUpdated(uint256 poolID, address greenToken);
    event SustainabilityTargetPercentUpdated(uint256 poolID, uint64 target);

    event AccountsAdded(uint256 poolID, address[] accounts, string[] accountNames);
    event AccountsRemoved(uint256 poolID, address[] accounts);

    event EditorAccessGranted(address[] accounts, uint256 poolID);
    event EditorAccessRevoked(address[] accounts, uint256 poolID);
}

struct CoolPoolSimple {
    string name;
    address creator;
    address greenToken;
    address[] editors;
    address[] accounts;
    uint64 sustainabilityTargetPercent;
    bool isPaused;
    bool isVerified;
    bool isImmutable;
    // to be used by CentralizedOracle
    uint256 firstCalculatedBlock;
    uint256 lastCalculatedBlock;
}
