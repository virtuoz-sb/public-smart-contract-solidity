// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {LibDiamond} from "./LibDiamond.sol";

contract Delegator {
    function diamondDelegateCall(bytes4 selector, bytes memory encodedWithSelector) internal returns (bytes memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address facetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(facetAddress).delegatecall(encodedWithSelector);
        if (success == false) {
            if (returnData.length > 0) {
                // solhint-disable-next-line
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(32, returnData), returnDataSize)
                }
            } else {
                revert("Delegate call failed");
            }
        }
        return returnData;
    }
}
