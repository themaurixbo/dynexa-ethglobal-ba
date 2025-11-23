// DYNEXA - HACKATHON ETHGLOBAL AR 2025
// DEV: MAURICIO LARREA SALINAS

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DynexaToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory name_,
        string memory symbol_,
        address admin,
        address initialReceiver,
        uint256 initialSupply
    ) ERC20(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);

        if (initialSupply > 0 && initialReceiver != address(0)) {
            _mint(initialReceiver, initialSupply);
        }
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
