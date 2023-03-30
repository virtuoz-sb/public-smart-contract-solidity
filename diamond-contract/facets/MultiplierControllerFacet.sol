// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage, Multiplier} from "../libraries/AppStorage.sol";
import "../libraries/Modifiers.sol";

contract MultiplierControllerFacet is Modifiers {
    bytes32 private constant MULTIPLIER_CONTROLLER_ADMIN_ROLE = keccak256("MULTIPLIER_CONTROLLER_ADMIN_ROLE");

    event UpdateMultiplicator(uint256 numerator, uint256 denumerator);

    function resetMultipliers() public onlyRole(MULTIPLIER_CONTROLLER_ADMIN_ROLE) {
        delete s.multipliers;
    }

    function addMultiplier(uint256 numerator, uint256 denumerator) public onlyRole(MULTIPLIER_CONTROLLER_ADMIN_ROLE) {
        addMultiplier(numerator, denumerator, block.number);
    }

    function addMultiplier(
        uint256 numerator,
        uint256 denumerator,
        uint256 blockNumber
    ) public onlyRole(MULTIPLIER_CONTROLLER_ADMIN_ROLE) {
        require(denumerator != 0, "Denumerator cannot be set to zero");
        require(blockNumber <= block.number, "Cannot update future multiplier");
        if (s.multipliers.length > 0) {
            require(s.multipliers[s.multipliers.length - 1].blockNumber < blockNumber, "BlockNumber should be sorted");
        }
        s.multipliers.push(Multiplier(blockNumber, numerator, denumerator));
    }

    function getMultipliers() public view returns (Multiplier[] memory) {
        return s.multipliers;
    }

    function getMultiplier() public view returns (Multiplier memory) {
        require(s.multipliers.length > 0, "Multipliers array is empty");
        return s.multipliers[s.multipliers.length - 1];
    }
}
