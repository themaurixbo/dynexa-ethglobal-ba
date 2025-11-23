// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DynexaToken.sol";
import "./DynexaCompanyRegistry.sol";

/// @dev Interfaz mínima del contrato de GiftTokens
interface IDynexaGiftToken {
    function mintGift(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;
}

contract DynexaQuestRewards is AccessControl {
    bytes32 public constant QUEST_ADMIN_ROLE = keccak256("QUEST_ADMIN_ROLE");
    bytes32 public constant QUEST_AGENT_ROLE = keccak256("QUEST_AGENT_ROLE");

    struct Quest {
        uint256 companyId;
        uint256 giftTokenId;       // 0 si la quest solo paga DYNEXA
        uint256 giftAmount;        // cantidad de GiftTokens
        uint256 dynexaAmount;      // cantidad DYNEXA
        uint256 maxCompletions;    // 0 = ilimitado
        uint256 completions;       // contador actual
        bool active;
    }

    DynexaToken public dynexaToken;
    IERC20 public usdcToken;          // opcional, por si luego cobras en USDC
    IDynexaGiftToken public giftToken;
    DynexaCompanyRegistry public companyRegistry;

    uint256 public nextQuestId = 1;
    mapping(uint256 => Quest) public quests;
    mapping(uint256 => mapping(address => bool)) public questCompleted; // questId => user => done?

    event QuestCreated(uint256 indexed questId, uint256 indexed companyId);
    event QuestCompleted(uint256 indexed questId, address indexed user);

    constructor(
        address dynexaToken_,
        address usdcToken_,
        address giftToken_,
        address companyRegistry_,
        address admin
    ) {
        dynexaToken = DynexaToken(dynexaToken_);
        usdcToken   = IERC20(usdcToken_);
        giftToken   = IDynexaGiftToken(giftToken_);
        companyRegistry = DynexaCompanyRegistry(companyRegistry_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(QUEST_ADMIN_ROLE, admin);
        _grantRole(QUEST_AGENT_ROLE, admin);
    }

    function createQuest(
        uint256 companyId,
        uint256 giftTokenId,
        uint256 giftAmount,
        uint256 dynexaAmount,
        uint256 maxCompletions
    ) external onlyRole(QUEST_ADMIN_ROLE) returns (uint256 questId) {
        // Para simplificar, asumimos companyId válido (se valida en backend / UI)
        require(giftAmount > 0 || dynexaAmount > 0, "no reward");

        questId = nextQuestId++;
        quests[questId] = Quest({
            companyId:      companyId,
            giftTokenId:    giftTokenId,
            giftAmount:     giftAmount,
            dynexaAmount:   dynexaAmount,
            maxCompletions: maxCompletions,
            completions:    0,
            active:         true
        });

        emit QuestCreated(questId, companyId);
    }

    /// @dev Llamado por backend / XMTP agent cuando el usuario completa la quest off-chain.
    function completeQuest(uint256 questId, address user)
        external
        onlyRole(QUEST_AGENT_ROLE)
    {
        Quest storage q = quests[questId];
        require(q.active, "quest inactive");
        require(!questCompleted[questId][user], "already completed");

        if (q.maxCompletions > 0) {
            require(q.completions < q.maxCompletions, "max completions reached");
        }

        questCompleted[questId][user] = true;
        q.completions += 1;

        // GiftTokens
        if (q.giftTokenId != 0 && q.giftAmount > 0) {
            giftToken.mintGift(user, q.giftTokenId, q.giftAmount);
        }

        // DYNEXA
        if (q.dynexaAmount > 0) {
            // Este contrato debe estar pre-fondeado con DYNEXA
            dynexaToken.transfer(user, q.dynexaAmount);
        }

        emit QuestCompleted(questId, user);
    }

    function setQuestActive(uint256 questId, bool active)
        external
        onlyRole(QUEST_ADMIN_ROLE)
    {
        quests[questId].active = active;
    }
}
