// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract BeeSmartProxy is ERC1967Proxy, Ownable {
    constructor(
        address _logic,
        bytes memory _data
    ) ERC1967Proxy(_logic, _data) {}

    function setImplementation(
        address _newLogic,
        bytes memory _data
    ) external onlyOwner {
        _upgradeToAndCall(_newLogic, _data, false);
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }
}
