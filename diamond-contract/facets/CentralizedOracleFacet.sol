// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage, CoolPool, Multiplier} from "../libraries/AppStorage.sol";
import "../libraries/Modifiers.sol";
import "../libraries/Delegator.sol";

import "hardhat/console.sol";

// TODO: Better error messages
// TODO: Access control, only oracle can call these.

contract CentralizedOracleFacet is Modifiers, Delegator {
    bytes32 private constant CENTRALIZED_ORACLE_ADMIN_ROLE = keccak256("CENTRALIZED_ORACLE_ADMIN_ROLE");

    event SubmitGasUsedCentralized(
        uint256 coolPoolID,
        uint256 gasUsed,
        uint256 lastCalculatedBlock,
        uint256 txCount,
        uint256 timestampTemp
    );

    function submitGasUsedForCoolPool(
        uint256 coolPoolID,
        uint256 gasUsed,
        uint256 lastCalculatedBlock,
        uint256 txCount,
        uint256 timestampTemp
    ) public onlyRole(CENTRALIZED_ORACLE_ADMIN_ROLE) {
        // TODO: Revert if coolpool does not exist
        // TODO: Remove timestampTemp

        // Update CoolPool
        CoolPool storage coolPool = s.coolPools[coolPoolID];
        require(lastCalculatedBlock > coolPool.lastCalculatedBlock, "The lastCalculatedBlock isn't valid!");
        coolPool.lastCalculatedBlock = lastCalculatedBlock;

        // Get the retire selector for the green token
        // Right now, only one green token
        address greenToken = coolPool.greenTokens[0];

        // Figure out the CO2 amount needed
        // BEWARE: May throw an overflow
        bytes4 getMultiplierSelector = bytes4(keccak256("getMultiplier()"));
        bytes memory getMultiplierReturnData = diamondDelegateCall(
            getMultiplierSelector,
            abi.encodeWithSelector(getMultiplierSelector)
        );
        Multiplier memory multiplier = abi.decode(getMultiplierReturnData, (Multiplier));
        uint256 co2Amount = (multiplier.numerator * gasUsed) / multiplier.denumerator;

        // Decrease the carbon token balance of that pool
        bytes4 useFundsSelector = bytes4(keccak256("useFunds(uint256,address,uint256)"));
        diamondDelegateCall(
            useFundsSelector,
            abi.encodeWithSelector(useFundsSelector, coolPoolID, greenToken, co2Amount)
        );

        // Retire the carbon token
        bytes4 retireSelector = bytes4(keccak256("retire(address,uint256)"));
        diamondDelegateCall(retireSelector, abi.encodeWithSelector(retireSelector, greenToken, co2Amount));

        emit SubmitGasUsedCentralized(coolPoolID, gasUsed, lastCalculatedBlock, txCount, timestampTemp);
    }
}
