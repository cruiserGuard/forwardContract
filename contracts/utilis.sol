// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

struct contractData{
        address   token;  // currency in contract
        address   AddressReferenceRate;   // benchmark rate
        uint8     decimal;                // benchamrk rate decimal
        uint32    period; // days
        uint128   NP;     // Notional Principal
        uint32    target;  // target rate
        uint128   upperLimit;   // boundry
        uint128   bottomLimit;  // boundry
        uint256   inception;        // block time
    }

library FixedPoint192 {
    uint8 internal constant RESOLUTION = 192;
    uint256 internal constant Q192 = 0x1000000000000000000000000000000000000000000000000;
}

library FixedPoint128 {
    uint8 internal constant RESOLUTION = 128;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

library FixedPoint80 {
    uint8 internal constant RESOLUTION = 80;
    uint256 internal constant Q80 = 0x10000000000000000;
}

library FixedPoint64 {
    uint8 internal constant RESOLUTION = 64;
    uint256 internal constant Q64 = 0x1000000000000;
}

library FixedPoint48 {
    uint8 internal constant RESOLUTION = 48;
    uint256 internal constant Q48 = 0x100000000;
}

library FixedPoint32 {
    uint8 internal constant RESOLUTION = 32;
    uint256 internal constant Q32 = 0x10000;
}

