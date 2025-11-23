// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./DynexaCompanyRegistry.sol";

contract DynexaGiftToken is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct GiftConfig {
        uint256 companyId;
        uint256 priceInDynexa;   // opcional, referencia de precio
        uint256 priceInUSDC;     // opcional, referencia de precio
        bool active;
    }

    DynexaCompanyRegistry public companyRegistry;
    mapping(uint256 => GiftConfig) public giftConfigs; // tokenId => config

    event GiftDefined(
        uint256 indexed tokenId,
        uint256 indexed companyId,
        uint256 priceInDynexa,
        uint256 priceInUSDC
    );

    constructor(
        string memory baseUri_,
        address admin,
        address companyRegistry_
    ) ERC1155(baseUri_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        companyRegistry = DynexaCompanyRegistry(companyRegistry_);
    }

    // ⬇️ ESTA FUNCIÓN ES LA QUE FALTABA
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setURI(string memory newuri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }
}