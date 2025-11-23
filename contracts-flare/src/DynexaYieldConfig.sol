// SPDX-License-Identifier: MIT

// DYNEXA - HACKATHON ETHGLOBAL AR 2025
// DEV: MAURICIO LARREA SALINAS
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract DynexaYieldConfig is AccessControl {
    bytes32 public constant RISK_ADMIN_ROLE = keccak256("RISK_ADMIN_ROLE");

    // Allocation caps (basis points, 10000 = 100%)
    uint16 public maxFtsoAllocationBps;   // e.g. 5000 = 50% of treasury
    uint16 public maxDefiAllocationBps;   // e.g. 4000 = 40%
    uint16 public minLiquidBufferBps;     // e.g. 3000 = 30% must stay liquid

    struct AssetRiskConfig {
        int256 priceFloor;       // micro-USD or similar
        int256 priceWarning;     // soft threshold
        uint16 maxDrawdownBps;   // e.g. 3000 = 30% max drawdown vs reference
    }

    AssetRiskConfig public xrpRisk;
    AssetRiskConfig public flrRisk;

    event AllocationCapsUpdated(
        uint16 maxFtsoAllocationBps,
        uint16 maxDefiAllocationBps,
        uint16 minLiquidBufferBps
    );

    event AssetRiskUpdated(
        string asset,
        int256 priceFloor,
        int256 priceWarning,
        uint16 maxDrawdownBps
    );

    constructor(
        address admin,
        uint16 _maxFtsoAllocationBps,
        uint16 _maxDefiAllocationBps,
        uint16 _minLiquidBufferBps
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RISK_ADMIN_ROLE, admin);

        maxFtsoAllocationBps = _maxFtsoAllocationBps;
        maxDefiAllocationBps = _maxDefiAllocationBps;
        minLiquidBufferBps   = _minLiquidBufferBps;
    }

    function setAllocationCaps(
        uint16 _maxFtsoAllocationBps,
        uint16 _maxDefiAllocationBps,
        uint16 _minLiquidBufferBps
    ) external onlyRole(RISK_ADMIN_ROLE) {
        require(
            _maxFtsoAllocationBps + _maxDefiAllocationBps <= 10000,
            "Total allocation too high"
        );
        maxFtsoAllocationBps = _maxFtsoAllocationBps;
        maxDefiAllocationBps = _maxDefiAllocationBps;
        minLiquidBufferBps   = _minLiquidBufferBps;

        emit AllocationCapsUpdated(
            _maxFtsoAllocationBps,
            _maxDefiAllocationBps,
            _minLiquidBufferBps
        );
    }

    function setXrpRiskConfig(
        int256 priceFloor,
        int256 priceWarning,
        uint16 maxDrawdownBps
    ) external onlyRole(RISK_ADMIN_ROLE) {
        xrpRisk = AssetRiskConfig(priceFloor, priceWarning, maxDrawdownBps);
        emit AssetRiskUpdated("XRP", priceFloor, priceWarning, maxDrawdownBps);
    }

    function setFlrRiskConfig(
        int256 priceFloor,
        int256 priceWarning,
        uint16 maxDrawdownBps
    ) external onlyRole(RISK_ADMIN_ROLE) {
        flrRisk = AssetRiskConfig(priceFloor, priceWarning, maxDrawdownBps);
        emit AssetRiskUpdated("FLR", priceFloor, priceWarning, maxDrawdownBps);
    }
}
