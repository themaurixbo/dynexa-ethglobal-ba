// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DynexaYieldConfig.sol";

/// @dev Simple generic yield vault interface (XRPFI / Firelight style)
interface IYieldVault {
    function deposit(uint256 assets) external;
    function withdraw(uint256 assets) external;
    function balanceOf(address account) external view returns (uint256);
}

/// @title DynexaFlareTreasury
/// @notice Main vault for FLR + FXRP on Flare. Tracks principal and yield.
contract DynexaFlareTreasury is AccessControl {
    bytes32 public constant TREASURY_ROLE      = keccak256("TREASURY_ROLE");
    bytes32 public constant STRATEGY_ROLE      = keccak256("STRATEGY_ROLE");
    bytes32 public constant FTSO_MANAGER_ROLE  = keccak256("FTSO_MANAGER_ROLE");

    IERC20 public immutable flrToken;   // representation of FLR if needed
    IERC20 public immutable fxrpToken;  // FXRP FAsset
    IYieldVault public xrpfVault;
    DynexaYieldConfig public yieldConfig;

    // FLR tracking
    uint256 public principalFLR;        // Total FLR funded into treasury
    uint256 public idleFLR;             // FLR not delegated / not used in strategies
    uint256 public ftsoDelegatedFLR;    // Accounting only (delegated voting power)
    uint256 public accumulatedFtsoYieldFLR;

    // FXRP tracking
    uint256 public principalFXRP;       // Total FXRP sent to treasury
    uint256 public idleFXRP;            // FXRP not yet in vault
    uint256 public stakedFXRP;          // FXRP deposited into XRPFI vault
    uint256 public accumulatedDefiYieldFXRP;

    event FlrDeposited(address indexed from, uint256 amount);
    event FlrWithdrawn(address indexed to, uint256 amount);
    event FxrpDeposited(address indexed from, uint256 amount);
    event FxrpWithdrawn(address indexed to, uint256 amount);

    event FxrpStaked(uint256 amount);
    event DefiYieldHarvested(uint256 amount);

    event FtsoDelegationRecorded(uint256 amount);
    event FtsoYieldRecorded(uint256 amount);
    event VaultUpdated(address newVault);
    event YieldConfigUpdated(address newConfig);

    constructor(
        address _flrToken,
        address _fxrpToken,
        address _xrpfVault,
        address _yieldConfig,
        address admin
    ) {
        require(_flrToken != address(0), "FLR token required");
        require(_fxrpToken != address(0), "FXRP token required");

        flrToken = IERC20(_flrToken);
        fxrpToken = IERC20(_fxrpToken);
        xrpfVault = IYieldVault(_xrpfVault);
        yieldConfig = DynexaYieldConfig(_yieldConfig);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(TREASURY_ROLE, admin);
        _grantRole(STRATEGY_ROLE, admin);
        _grantRole(FTSO_MANAGER_ROLE, admin);
    }

    // --- Admin setters ---

    function setVault(address _xrpfVault) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_xrpfVault != address(0), "zero vault");
        xrpfVault = IYieldVault(_xrpfVault);
        emit VaultUpdated(_xrpfVault);
    }

    function setYieldConfig(address _yieldConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_yieldConfig != address(0), "zero config");
        yieldConfig = DynexaYieldConfig(_yieldConfig);
        emit YieldConfigUpdated(_yieldConfig);
    }

    // --- FLR flows ---

    function depositFLR(uint256 amount) external onlyRole(TREASURY_ROLE) {
        require(amount > 0, "amount = 0");
        require(
            flrToken.transferFrom(msg.sender, address(this), amount),
            "FLR transfer failed"
        );
        principalFLR += amount;
        idleFLR += amount;
        emit FlrDeposited(msg.sender, amount);
    }

    function withdrawFLR(address to, uint256 amount) external onlyRole(TREASURY_ROLE) {
        require(to != address(0), "zero address");
        require(amount <= idleFLR, "not enough idle FLR");
        idleFLR -= amount;
        require(flrToken.transfer(to, amount), "FLR transfer failed");
        emit FlrWithdrawn(to, amount);
    }

    /// @dev Accounting helper to register FLR delegated to FTSO.
    ///      Real delegation is done off-chain / via another contract.
    function recordFtsoDelegation(uint256 amount) external onlyRole(STRATEGY_ROLE) {
        require(amount <= idleFLR, "not enough idle FLR");
        idleFLR -= amount;
        ftsoDelegatedFLR += amount;
        emit FtsoDelegationRecorded(amount);
    }

    /// @dev Called by DynexaFTSOManager when FLR rewards are claimed.
    function recordFtsoYield(uint256 amount) external onlyRole(FTSO_MANAGER_ROLE) {
        require(amount > 0, "amount = 0");
        accumulatedFtsoYieldFLR += amount;
        // Assumes FLR tokens are already transferred into this contract by caller.
        emit FtsoYieldRecorded(amount);
    }

    // --- FXRP flows ---

    function depositFXRP(uint256 amount) external onlyRole(TREASURY_ROLE) {
        require(amount > 0, "amount = 0");
        require(
            fxrpToken.transferFrom(msg.sender, address(this), amount),
            "FXRP transfer failed"
        );
        principalFXRP += amount;
        idleFXRP += amount;
        emit FxrpDeposited(msg.sender, amount);
    }

    function withdrawFXRP(address to, uint256 amount) external onlyRole(TREASURY_ROLE) {
        require(to != address(0), "zero address");
        require(amount <= idleFXRP, "not enough idle FXRP");
        idleFXRP -= amount;
        require(fxrpToken.transfer(to, amount), "FXRP transfer failed");
        emit FxrpWithdrawn(to, amount);
    }

    // --- DeFi / XRPFI vault ---

    /// @dev Stake FXRP into XRPFI / Firelight vault.
    function stakeToVault(uint256 amount) external onlyRole(STRATEGY_ROLE) {
        require(amount > 0, "amount = 0");
        require(amount <= idleFXRP, "not enough idle FXRP");

        idleFXRP -= amount;
        stakedFXRP += amount;

        // Aquí podrías agregar chequeo contra yieldConfig.maxDefiAllocationBps()

        require(
            fxrpToken.approve(address(xrpfVault), amount),
            "approve failed"
        );
        xrpfVault.deposit(amount);

        emit FxrpStaked(amount);
    }

    /// @dev Harvests DeFi yield by reading vault balance and updating accounting.
    function harvestDefiYield() external onlyRole(STRATEGY_ROLE) {
        uint256 currentValue = xrpfVault.balanceOf(address(this));
        require(currentValue >= stakedFXRP, "vault under water");

        uint256 yieldAmount = currentValue - stakedFXRP;
        if (yieldAmount > 0) {
            accumulatedDefiYieldFXRP += yieldAmount;
            emit DefiYieldHarvested(yieldAmount);
        }
    }

    /// @dev Withdraw FXRP from the vault (e.g. to de-risk or redeem).
    function withdrawFromVault(uint256 amount) external onlyRole(STRATEGY_ROLE) {
        require(amount > 0, "amount = 0");
        require(amount <= stakedFXRP, "not enough staked FXRP");

        xrpfVault.withdraw(amount);
        stakedFXRP -= amount;
        idleFXRP += amount;
    }

    // --- Views ---

    function totalFXRPInStrategy() external view returns (uint256) {
        return stakedFXRP;
    }

    function totalFXRPIdle() external view returns (uint256) {
        return idleFXRP;
    }

    function totalFLRIdle() external view returns (uint256) {
        return idleFLR;
    }
}
