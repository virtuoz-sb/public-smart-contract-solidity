// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/AppStorage.sol";
import "../libraries/Modifiers.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AccessControlFacet is Modifiers {
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function grantRole(bytes32 role, address account) public onlyOwner systemUnpaused {
        if (!hasRole(role, account)) {
            s.roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function revokeRole(bytes32 role, address account) public onlyOwner systemUnpaused {
        if (hasRole(role, account)) {
            s.roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    function pause(bool systemPaused) public onlyOwner {
        s.systemPaused = systemPaused;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _hasRole(role, account);
    }
}
