// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import './interfaces/IFamosoFactory.sol';
import './FamosoPair.sol';

contract FamosoFactory is IFamosoFactory {
    address public override feeTo;
    address public override feeToSetter;

    uint public setterLockedTimeStamp;
    uint public feeToLockedTimeStamp;

    uint public setterlockingPeriod = 31536000; // 1year
    uint public feeToLockingPeriod = 15768000;    // 6 months
    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event SetFeeTo(address indexed feeTo, uint);
    event SetFeeToSetter(address indexed feeToSetter, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
        setterLockedTimeStamp = block.timestamp;
        feeToLockedTimeStamp = 0;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(FamosoPair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'Famoso: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Famoso: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Famoso: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(FamosoPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        FamosoPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'Famoso: FORBIDDEN');
        require(_feeTo != address(0), 'Famoso: ZERO_ADDRESS');
        require(feeToLockedTimeStamp + feeToLockingPeriod < block.timestamp, 'Famoso: NOT IN TIME');
        feeTo = _feeTo;
        feeToLockedTimeStamp = block.timestamp;
        emit SetFeeTo(feeTo, block.timestamp);
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'Famoso: FORBIDDEN');
        require(_feeToSetter != address(0), 'Famoso: ZERO_ADDRESS');
        require(setterLockedTimeStamp + setterlockingPeriod < block.timestamp, 'Famoso: NOT IN TIME');
        feeToSetter = _feeToSetter;
        setterLockedTimeStamp = block.timestamp;
        emit SetFeeToSetter(feeToSetter, block.timestamp);
    }

}
