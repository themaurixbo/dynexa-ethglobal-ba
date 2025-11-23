// DYNEXA - HACKATHON ETHGLOBAL AR 2025
// DEV: MAURICIO LARREA SALINAS

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DynexaFlareTreasury.sol";

/// @title DynexaFTSOManager
/// @notice Helper to forward FTSO rewards to DynexaFlareTreasury.
contract DynexaFTSOManager is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    DynexaFlareTreasury public immutable treasury;
    IERC20 public immutable flrToken;

    event FtsoRewardsForwarded(uint256 amount);

    constructor(
        address _treasury,
        address _flrToken,
        address admin
    ) {
        require(_treasury != address(0), "treasury = 0");
        require(_flrToken != address(0), "flrToken = 0");

        treasury = DynexaFlareTreasury(_treasury);
        flrToken = IERC20(_flrToken);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    /// @dev En integración real, este contrato reclamaría recompensas FTSO.
    ///      Para el hackathon, asumimos que este contrato recibe FLR rewards,
    ///      y luego las envía a la Tesorería y registra el yield.
    function forwardRewardsToTreasury(uint256 amount) external onlyRole(MANAGER_ROLE) {
        require(amount > 0, "amount = 0");
        require(
            flrToken.transfer(address(treasury), amount),
            "FLR transfer failed"
        );
        treasury.recordFtsoYield(amount);
        emit FtsoRewardsForwarded(amount);
    }
}
