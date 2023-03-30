// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage, CoolPool} from "../libraries/AppStorage.sol";
import "../libraries/Modifiers.sol";
import "../interfaces/ICoolPoolFacet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CoolPoolFacet is ICoolPoolFacet, Modifiers {
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier isEditable(uint256 poolID) {
        require(
            s.coolPools[poolID].editors.contains(msg.sender) || msg.sender == s.coolPools[poolID].creator,
            "Caller is not an editor!"
        );
        require(!s.coolPools[poolID].isImmutable, "Pool is immutable!");
        _;
    }

    modifier onlyCreator(uint256 poolID) {
        require(msg.sender == s.coolPools[poolID].creator, "Modifiers: You are not the creator!");
        _;
    }

    bytes32 private constant COOLPOOL_ADMIN_ROLE = keccak256("COOLPOOL_ADMIN_ROLE");

    /** ONLY ADMINS >>>>>>>>> */

    function createCoolPool(
        string calldata projectName,
        address[] calldata accounts,
        string[] calldata accountNames,
        address greenToken,
        uint64 sustainabilityTargetPercent,
        bool offsetPastTxs,
        bool isImmutable
    ) public onlyRole(COOLPOOL_ADMIN_ROLE) systemUnpaused returns (uint256 poolID) {
        require(sustainabilityTargetPercent >= 100, "Sustainability target should be equal or above 100");

        s.lastPoolID += 1;
        poolID = s.lastPoolID;

        s.coolPools[poolID].name = projectName;
        s.coolPools[poolID].creator = msg.sender;
        s.coolPools[poolID].greenTokens = [greenToken];
        s.coolPools[poolID].sustainabilityTargetPercent = sustainabilityTargetPercent;
        s.coolPools[poolID].isImmutable = isImmutable;
        s.coolPools[poolID].isVerified = true;
        if (!offsetPastTxs) s.coolPools[poolID].firstCalculatedBlock = block.number;

        for (uint256 i; i < accounts.length; i++) {
            s.coolPools[poolID].accounts.add(accounts[i]);
        }

        s.creatorToPoolIDs[msg.sender].push(poolID);

        emit PoolCreated(
            poolID,
            projectName,
            msg.sender,
            greenToken,
            accounts,
            accountNames,
            sustainabilityTargetPercent,
            offsetPastTxs,
            isImmutable
        );
    }

    /** <<<<<<<<<<<< ONLY ADMINS */

    /** ONLY COOLPOOL CREATORS >>>>>>>>>> */

    function manageEditorAccess(
        address[] calldata editorsToBeAdded,
        address[] calldata editorsToBeRemoved,
        uint256 poolID
    ) public onlyCreator(poolID) {
        if (editorsToBeRemoved.length > 0) {
            for (uint256 i; i < editorsToBeRemoved.length; i++) {
                s.coolPools[poolID].accounts.remove(editorsToBeRemoved[i]);
            }
            emit EditorAccessRevoked(editorsToBeRemoved, poolID);
        }

        if (editorsToBeAdded.length > 0) {
            for (uint256 i; i < editorsToBeAdded.length; i++) {
                s.coolPools[poolID].accounts.add(editorsToBeAdded[i]);
            }
            emit EditorAccessGranted(editorsToBeAdded, poolID);
        }
    }

    function makeImmutable(uint256 poolID) public isEditable(poolID) onlyCreator(poolID) systemUnpaused {
        s.coolPools[poolID].isImmutable = true;

        emit MadeImmutable(poolID);
    }

    /** <<<<<<<<<<< ONLY COOLPOOL CREATORS */

    /** ONLY COOLPOOL POOL CREATORS & EDITORS >>>>>>>>>> */

    function updateCoolPool(
        uint256 poolID,
        string calldata name,
        address greenToken,
        uint64 sustainabilityTargetPercent,
        address[] calldata accountsToBeAdded,
        string[] memory accountNamesToBeAdded,
        address[] calldata accountsToBeRemoved
    ) public isEditable(poolID) systemUnpaused {
        require(sustainabilityTargetPercent >= 100, "Sustainability target should be equal or above 100");

        if (bytes(name).length > 0) {
            s.coolPools[poolID].name = name;
            emit NameUpdated(poolID, name);
        }
        if (greenToken != address(0)) {
            s.coolPools[poolID].greenTokens[0] = greenToken;
            emit GreenTokenUpdated(poolID, greenToken);
        }
        if (sustainabilityTargetPercent > 0) {
            s.coolPools[poolID].sustainabilityTargetPercent = sustainabilityTargetPercent;
            emit SustainabilityTargetPercentUpdated(poolID, sustainabilityTargetPercent);
        }

        if (accountsToBeAdded.length > 0) {
            require(
                accountsToBeAdded.length == accountNamesToBeAdded.length,
                "'accounts' and 'accountNames' should have the same length."
            );
            for (uint256 i; i < accountsToBeAdded.length; i++) {
                s.coolPools[poolID].accounts.add(accountsToBeAdded[i]);
            }
            emit AccountsAdded(poolID, accountsToBeAdded, accountNamesToBeAdded);
        }
        if (accountsToBeRemoved.length > 0) {
            for (uint256 i; i < accountsToBeRemoved.length; i++) {
                s.coolPools[poolID].accounts.remove(accountsToBeRemoved[i]);
            }
            emit AccountsRemoved(poolID, accountsToBeRemoved);
        }
    }

    function pauseCoolPool(uint256 poolID, bool isPaused) public systemUnpaused {
        require(
            s.coolPools[poolID].editors.contains(msg.sender) || msg.sender == s.coolPools[poolID].creator,
            "Caller is not an editor!"
        );

        s.coolPools[poolID].isPaused = isPaused;

        emit PoolPaused(poolID, isPaused);
    }

    /** <<<<<<<<<<< ONLY COOLPOOL CREATORS & EDITORS */

    /** GETTERS >>>>>>>>> */

    function getCoolPool(uint256 poolID) public view returns (CoolPoolSimple memory simple) {
        simple.name = s.coolPools[poolID].name;
        simple.creator = s.coolPools[poolID].creator;
        simple.greenToken = s.coolPools[poolID].greenTokens[0];
        simple.editors = s.coolPools[poolID].editors.values();
        simple.accounts = s.coolPools[poolID].accounts.values();
        simple.sustainabilityTargetPercent = s.coolPools[poolID].sustainabilityTargetPercent;
        simple.isPaused = s.coolPools[poolID].isPaused;
        simple.isVerified = s.coolPools[poolID].isVerified;
        simple.isImmutable = s.coolPools[poolID].isImmutable;
        simple.firstCalculatedBlock = s.coolPools[poolID].firstCalculatedBlock;
        simple.lastCalculatedBlock = s.coolPools[poolID].lastCalculatedBlock;
    }

    function getCreatorPools(address account) public view returns (uint256[] memory) {
        return s.creatorToPoolIDs[account];
    }

    /** <<<<<<<<<< GETTERS */
}
