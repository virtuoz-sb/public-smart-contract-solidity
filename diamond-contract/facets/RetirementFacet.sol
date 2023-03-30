// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/AppStorage.sol";
import "../libraries/Modifiers.sol";
import "../libraries/Delegator.sol";
import "../interfaces/IRetirementFacet.sol";
import "../interfaces/retirements/IRetireMossOnEthereum.sol";
import "../interfaces/retirements/IRetireMossOnPolygon.sol";
import "../interfaces/retirements/IRetireBurn.sol";
import "../interfaces/retirements/IRetireFlowcarbon.sol";
import "../interfaces/retirements/IRetireToucan.sol";
import "hardhat/console.sol";

// TODO: The integrations need to be public to have selectors available
// but only `this` should be able to call them. Kind of internal.
// We could probably write a new modifier like `onlyThis`.

contract RetirementFacet is Modifiers, IRetirementFacet, Delegator {
    bytes32 private constant CARBON_TOKEN_MANAGER_ROLE = keccak256("CARBON_TOKEN_MANAGER_ROLE");

    function addCarbonTokenRetireSelector(
        address carbonTokenAddress,
        string calldata name,
        bytes4 selector
    ) external onlyRole(CARBON_TOKEN_MANAGER_ROLE) {
        s.carbonTokenToRetireSelector[carbonTokenAddress] = selector;
        emit CarbonTokenRetireSelectorAdded(carbonTokenAddress, name);
    }

    function removeCarbonTokenRetireSelector(address carbonTokenAddress) external onlyRole(CARBON_TOKEN_MANAGER_ROLE) {
        s.carbonTokenToRetireSelector[carbonTokenAddress] = bytes4(0);
        emit CarbonTokenRetireSelectorRemoved(carbonTokenAddress);
    }

    function getCarbonTokenRetireSelector(address carbonTokenAddress) public view returns (bytes4) {
        bytes4 selector = s.carbonTokenToRetireSelector[carbonTokenAddress];
        require(selector != bytes4(0), "selector cannot be zero");
        return selector;
    }

    function retire(address carbonToken, uint256 amount) public override {
        /* This function can be a service on its own,
         * like a carbon token retirement aggregator
         * if we spend a little effort to use OffsetOnBehalf.
         * Not important for beta but TODO
         */
        bytes4 selector = getCarbonTokenRetireSelector(carbonToken);
        diamondDelegateCall(selector, abi.encodeWithSelector(selector, carbonToken, amount));
        emit Retired(carbonToken, amount);
    }

    /** INTEGRATIONS >>>>>>>>> */

    function retireBurn(address carbonToken, uint256 amount) public {
        IRetireBurn token = IRetireBurn(carbonToken);
        token.burn(address(this), amount);
        emit Retired(carbonToken, amount);
    }

    function retireMossOnPolygon(address carbonToken, uint256 amount) public {
        IRetireMossOnPolygon(carbonToken).offsetCarbon(amount, "", "");
        emit Retired(carbonToken, amount);
    }

    function retireMossOnEthereum(address carbonToken, uint256 amount) public {
        IRetireMossOnEthereum(carbonToken).offsetTransaction(amount, "", "");
        emit Retired(carbonToken, amount);
    }

    function retireFlowcarbon(address carbonToken, uint256 amount) public {
        IRetireFlowcarbon(carbonToken).offset(amount);
        emit Retired(carbonToken, amount);
    }

    function retireToucan(address carbonToken, uint256 amount) public {
        (address[] memory tco2s, uint256[] memory amounts) = IRetireToucanNCT(carbonToken).redeemAuto2(amount);
        require(tco2s.length == amounts.length, "Toucan retirement returned arrays with different lengths");

        for (uint256 i = 0; i < tco2s.length; i++) {
            // This is a bug that will be fixed on the mainnet soon.
            // https://github.com/ToucanProtocol/contracts/issues/5
            if (amounts[i] != 0) {
                IRetireToucanTCO2(tco2s[i]).retire(amounts[i]);
            }
        }
    }

    /** <<<<<<<<<<<< INTEGRATIONS */
}
