// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Order {
    enum Status {
        UNKNOWN,       // occupate the default status
        NORMAL,        // normal status
        ADJUSTED,      // buyer adjuste amount
        CONFIRMED,     // seller confirmed
        CANCELLED,     // buyer adjust amount to 0
        SELLERDISPUTE, // seller dispute
        BUYERDISPUTE,  // buyer dispute
        LOCKED,        // both buyer and seller disputed
        SELLERWIN,     // community decide seller win
        BUYERWIN       // community decide buyer win
    }

    struct Record {
        uint256 orderId;
        uint256 sellAmount;
        address payToken;
        uint64  updatedAt;
        address buyer;
        address seller;
        Status  currStatus;
        Status  prevStatus;
        uint256 sellerFee;
        uint256 buyerFee;
    }

    struct Rewards {
        uint128 buyerRewards;
        uint128 sellerRewards;
        uint128 buyerAirdropPoints;
        uint128 sellerAirdropPoints;
        uint128 buyerReputation;
        uint128 sellerReputation;
    }

    struct AdjustInfo {
        uint256 preAmount;
        uint256 curAmount;
    }

    function toStatus(Record storage r, Status s) internal {
        r.prevStatus = r.currStatus;
        r.currStatus = s;
        r.updatedAt = uint64(block.timestamp);
    }
}