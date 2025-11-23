// DYNEXA - HACKATHON TIERRA DE BUILDERS   2025
// DEV: MAURICIO LARREA SALINAS

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./DynexaFlareTreasury.sol";

/// @title DynexaSubsidyEngine
/// @notice Converts treasury yield into "subsidy units" per brand/company.
contract DynexaSubsidyEngine is AccessControl {
    bytes32 public constant SUBSIDY_ADMIN_ROLE = keccak256("SUBSIDY_ADMIN_ROLE");

    DynexaFlareTreasury public immutable treasury;

    // Simple mapping: companyId => subsidyUnits
    mapping(uint256 => uint256) public companySubsidyUnits;

    event SubsidyAssigned(uint256 indexed companyId, uint256 amount);
    event SubsidyConsumed(uint256 indexed companyId, uint256 amount);

    constructor(address _treasury, address admin) {
        require(_treasury != address(0), "treasury = 0");
        treasury = DynexaFlareTreasury(_treasury);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SUBSIDY_ADMIN_ROLE, admin);
    }

    /// @dev Demo sencillo: asignar subsidios manualmente.
    ///      Versión avanzada puede leer yields + actividad vía FDC.
    function assignSubsidy(
        uint256 companyId,
        uint256 amount
    ) external onlyRole(SUBSIDY_ADMIN_ROLE) {
        companySubsidyUnits[companyId] += amount;
        emit SubsidyAssigned(companyId, amount);
    }

    /// @dev Llamado por el core de Dynexa cuando se usan subsidios para campañas.
    function consumeSubsidy(
        uint256 companyId,
        uint256 amount
    ) external onlyRole(SUBSIDY_ADMIN_ROLE) {
        require(companySubsidyUnits[companyId] >= amount, "not enough subsidy");
        companySubsidyUnits[companyId] -= amount;
        emit SubsidyConsumed(companyId, amount);
    }

    /// @dev Helper view: snapshot de yields para UI / analytics.
    function getYieldSnapshot()
        external
        view
        returns (uint256 ftsoYieldFLR, uint256 defiYieldFXRP)
    {
        ftsoYieldFLR = treasury.accumulatedFtsoYieldFLR();
        defiYieldFXRP = treasury.accumulatedDefiYieldFXRP();
    }
}
