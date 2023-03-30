// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeManager is Ownable {

    uint256 public feeByMillion = 25000; // 2.5%
    uint256 public constant MAX_FEE_BY_MILLION = 30000; // 3%

    event ChangedFee(uint256 feeByMillion);

    function setFeeByMillion(uint256 _feeByMillion) external onlyOwner {
        require(
            _feeByMillion < MAX_FEE_BY_MILLION, 
            "Invalid Fee"
        );
        feeByMillion = _feeByMillion;
        emit ChangedFee(feeByMillion);
    }
    
}