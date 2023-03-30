// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {AppStorage} from "./AppStorage.sol";
import {LibDiamond} from "./LibDiamond.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "Modifiers: Account ",
                        Strings.toHexString(account),
                        " doesn't have the role ",
                        Strings.toHexString(uint256(role), 32),
                        "."
                    )
                )
            );
        }
    }

    modifier systemUnpaused() {
        require(!s.systemPaused, "Modifiers: The system is paused!");
        _;
    }

    modifier coolPoolUnpaused(uint256 poolID) {
        require(!s.coolPools[poolID].isPaused, "Modifiers: CoolPool is paused!");
        _;
    }

    function _hasRole(bytes32 role, address account) internal view virtual returns (bool) {
        return s.roles[role].members[account];
    }
}
