// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Rebate {
    function calculateRebate(
        uint256 totalRebate,
        uint256[] memory relationIds
    ) external pure returns (uint256[] memory) {
        uint256 length = relationIds.length;
        uint256[] memory rebates = new uint256[](length);

        for (uint256 i = 0; i < length - 1; ++i) {
            if (relationIds[i + 1] == 0 || i == length - 1)  {
                rebates[i] = totalRebate;
                break;
            } else {
                rebates[i] = totalRebate * 0.9E18 / 1E18;   // 90% for current argent
                totalRebate = totalRebate * 0.1E18 / 1E18;  // 10% for upper argent
            }
        }

        return rebates;
    }
}
