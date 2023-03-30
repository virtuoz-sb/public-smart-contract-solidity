// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct CoolPool {
    string name;
    address creator;
    address[] greenTokens;
    EnumerableSet.AddressSet editors;
    EnumerableSet.AddressSet accounts;
    uint64 sustainabilityTargetPercent;
    bool isPaused;
    bool isVerified;
    bool isImmutable;
    uint256 currentDepositPeriod;
    mapping(address => PoolInfo) poolInfos; // token => PoolInfo
    // to be used by CentralizedOracle
    uint256 firstCalculatedBlock;
    uint256 lastCalculatedBlock;
}

struct PoolInfo {
    // when we're inside PoolInfo, we know: poolID and token
    mapping(address => UserDeposit) depositors; // depositor address => UserDeposit
    mapping(uint256 => PeriodInfo) periodInfos; // period => PeriodInfo
    uint256 currentTotalDeposit; // this will change with every deposit, but we'll record it at each period change
}

struct PeriodInfo {
    uint256 latestTotalDeposit;
    uint256 usedAmount;
}

struct UserDeposit {
    uint256 balance;
    uint256 lastDepositPeriod;
}

struct CoolReserve {
    uint256 balance;
    uint256 sellPrice;
}

struct Multiplier {
    uint256 blockNumber;
    uint256 numerator;
    uint256 denumerator;
}

struct RoleData {
    mapping(address => bool) members;
}

struct AppStorage {
    mapping(uint256 => CoolPool) coolPools; // pool ID => cool pool
    mapping(address => uint256[]) creatorToPoolIDs; // creator address => pool ids
    mapping(address => CoolReserve) coolReserves;
    mapping(bytes32 => RoleData) roles;
    uint256 lastPoolID;
    bool systemPaused; // The flag that can freeze the whole system
    Multiplier[] multipliers;
    mapping(address => bytes4) carbonTokenToRetireSelector;
}
