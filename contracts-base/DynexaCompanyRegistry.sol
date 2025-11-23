// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract DynexaCompanyRegistry is AccessControl {
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    struct Company {
        string name;
        address owner;          // dueño / brand admin
        address rewardsWallet;  // wallet donde recibe DYNEXA/USDC si hace falta
        bool active;
    }

    uint256 public nextCompanyId = 1;
    mapping(uint256 => Company) public companies;

    event CompanyRegistered(uint256 indexed companyId, string name, address owner);
    event CompanyUpdated(uint256 indexed companyId);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REGISTRAR_ROLE, admin);
    }

    function registerCompany(
        string calldata name,
        address owner,
        address rewardsWallet
    ) external onlyRole(REGISTRAR_ROLE) returns (uint256 companyId) {
        require(owner != address(0), "owner = 0");
        require(bytes(name).length > 0, "name empty");

        companyId = nextCompanyId++;
        companies[companyId] = Company({
            name: name,
            owner: owner,
            rewardsWallet: rewardsWallet,
            active: true
        });

        emit CompanyRegistered(companyId, name, owner);
    }

    function setCompanyActive(uint256 companyId, bool active) external onlyRole(REGISTRAR_ROLE) {
        require(companies[companyId].owner != address(0), "company not found");
        companies[companyId].active = active;
        emit CompanyUpdated(companyId);
    }

    function updateCompanyWallet(
        uint256 companyId,
        address rewardsWallet
    ) external {
        Company storage c = companies[companyId];
        require(c.owner == msg.sender || hasRole(REGISTRAR_ROLE, msg.sender), "not allowed");
        c.rewardsWallet = rewardsWallet;
        emit CompanyUpdated(companyId);
    }
}
