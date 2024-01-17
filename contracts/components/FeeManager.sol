// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract FeeManager is Ownable {

    constructor(address _owner) {
        _transferOwnership(_owner);
    }
}