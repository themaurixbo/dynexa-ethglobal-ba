ETHGLOBAL AR 2025

# README_CDP  
Dynexa x Coinbase Developer Platform  

---

## 1. Overview

**Dynexa** is a Web3 rewards layer that transforms brand marketing budgets into on-chain, gamified rewards for users (quests, missions, GiftTokens, and the DYNEXA coin).

For the **Coinbase Developer Platform (CDP)** track, Dynexa uses Coinbase’s infrastructure to:

- Remove all wallet friction for non-crypto users with **embedded wallets**.
- Make it trivial for brands to fund their onchain reward budgets using **Coinbase Pay** as a fiat → crypto ramp.
- Route this funded capital into Dynexa’s reward engine (and, in the bigger picture, into our Flare Yield Engine and onchain campaigns).

CDP lets us ship a **Web2-like UX** for onboarding and payments, while Dynexa handles the loyalty and DeFi logic behind the scenes.

---

## 2. CDP Products Used

We integrate the following components of Coinbase Developer Platform:

1. **CDP Embedded Wallets (for end-users)**  
   - Automatically creates and manages wallets for Dynexa users on Base (or another CDP-supported EVM chain) when they sign up.  
   - No seed phrases, no separate wallet download — everything is embedded into the Dynexa app experience.  
   - All reward-related transactions (earning, claiming, redeeming) are signed through the CDP embedded wallet.

2. **Coinbase Pay (onchain payment acceptance)**  
   - Lets brands fund their Dynexa marketing budget by paying with fiat/crypto through a familiar Coinbase UI.  
   - Funds are delivered as USDC/crypto directly to a Dynexa treasury address onchain.  
   - This capital becomes the base for campaigns, quests, and—to the extent we connect to Flare—the source that feeds our yield engine.


---

## 3. User & Brand Flows with CDP

### 3.1 User Onboarding & Embedded Wallet Creation

**Goal:** A user can start using Dynexa, earn rewards, and redeem them **without ever touching a seed phrase**.

**Flow:**

1. The user signs up in the Dynexa web or mobile app using:
   - Email, social login or OAuth (as supported by our auth layer).
2. On first login, the backend (or frontend via SDK) calls **CDP Embedded Wallets** to:
   - Create an embedded wallet for the user.
   - Store the wallet association (userId ↔ CDP walletId) in Dynexa’s database.
3. The user’s actions in the app:
   - Joining quests,
   - Completing missions,
   - Claiming rewards,
   - Redeeming GiftTokens at merchants,
   are all mapped to **onchain transactions** signed via the embedded wallet behind the scenes.

To the user, it feels like a normal app with “points and rewards”; under the hood, they own a real wallet and real onchain assets.

---

### 3.2 Brand Onboarding & Funding with Coinbase Pay

**Goal:** Make it trivial for brands to fund their Dynexa campaigns using fiat and familiar Coinbase flows.

**Flow:**

1. A brand creates a **Dynexa Business Account** in the web dashboard.
2. In the **“Top up marketing budget”** screen, the brand selects:
   - Desired amount (e.g. 2,000 USD),
   - Asset (e.g. USDC),
   - Target network (e.g. Base).
3. The dashboard opens a **Coinbase Pay** flow:
   - The brand can pay using funds from their Coinbase account, bank card, or other supported methods.
4. Coinbase Pay delivers the funds directly to the **Dynexa Treasury address**:
   - The treasury address is controlled by Dynexa’s infrastructure (and/or smart contracts).
5. Dynexa credits the brand’s:
   - “Onchain Marketing Budget” balance in the dashboard.
   - This budget can now be used to:
     - Create quests and campaigns.
     - Issue GiftTokens and DYNEXA rewards to users.
     - Internally we, as DYNEXA OWNERS  send part of that capital into Flare for yield generation.

---

## 4. Architecture Overview

### 4.1 High-level components

- **Dynexa Web / Mobile App** (JUSTO MOCKUPS)
  - Frontend where users see their balance, quests, and rewards.
  - Communicates with:
    - Dynexa backend APIs.
    - CDP Embedded Wallet SDK for signing transactions.

- **Dynexa Backend**
  - Manages users, brands, quests, and campaigns.
  - Keeps mappings:
    - `userId ↔ embeddedWalletId`
    - `brandId ↔ treasurySubaccount / funding history`
  - Orchestrates reward mints and redemptions via onchain contracts and CDP wallets.

- **Onchain Smart Contracts (Base or other CDP-supported chain)**
  - `DynexaCompanyTreasury`: stores brand-funded budgets and defines spending rules.
  - `DynexaGiftToken`: ERC-1155 or ERC-721/20 contract representing GiftTokens issued by brands.
  - `DynexaRewardEngine`: logic to grant rewards to users when quests are completed.

- **Coinbase Developer Platform**
  - **Embedded Wallets**: secure, abstracted wallets for end-users.
  - **Coinbase Pay**: fiat/crypto onramp that funds Dynexa’s treasury addresses.

---

## 5. Security & UX Considerations

- **Security:**
  - Users never handle private keys or seed phrases directly.
  - CDP manages sensitive wallet operations, reducing surface area for error.
  - On-brand and secure flow for brands to fund their budgets via Coinbase Pay.

- **UX:**
  - Onboarding feels Web2, but users still truly own their rewards in an onchain wallet.
  - Brands don’t need to understand onchain transfers or gas:
    - They see “top up budget” and “launch campaign”.
  - Dynexa manages all the complexity between CDP, Flare yield, and reward issuance.

---

## 6. Why CDP Matters for Dynexa

- **For users:** reduces the friction to almost zero. They sign up and start earning instantly — no MetaMask, no seed phrases.  
- **For brands:** makes it possible to fund global, onchain rewards using familiar fiat workflows.  
- **For Dynexa:** CDP turns wallet and funding infrastructure into a commodity, letting us focus on:
  - Gamified rewards,
  - Multi-brand GiftTokens,
  - Yield-powered loyalty across Flare and other chains.

CDP is the glue that connects Web2 brands and mainstream users to Dynexa’s onchain reward engine.
Turn loyalty into a game everyone wins

## CONTRACTS DEPLOYED AND VERIFIED




DynexaToken.sol
ERC20 para el token nativo DYNEXA (1:1 visual con USDC en el UX).
0xC26a26Ad325ae0Aa0f768fe90e3DC11bA794a4F5
https://sepolia.basescan.org/address/0xC26a26Ad325ae0Aa0f768fe90e3DC11bA794a4F5#code


DynexaCompanyRegistry.sol
Registro de empresas/brands que participan en Dynexa.
0x30165DEed5D5A05cE696f2195d4E2363219f9639
https://sepolia.basescan.org/address/0x30165DEed5D5A05cE696f2195d4E2363219f9639


DynexaGiftToken.sol (ERC1155)
GiftTokens multi-brand, cada tokenId = un premio/cupón/camisa/entrada, etc.
0xd51B871d4a68293a21BC172ce45E099Af1014790
https://sepolia.basescan.org/address/0xd51B871d4a68293a21BC172ce45E099Af1014790#code



DynexaQuestRewards.sol
Capa de campañas/quests sobre Base:
vincula companyId, tokenId de GiftToken y emite recompensas (DYNEXA y/o GiftTokens) cuando el backend/XMTP agent marca una misión como completada.
0x76e8DA340B06850C8a397a880e317c288949f590
https://sepolia.basescan.org/address/0x76e8DA340B06850C8a397a880e317c288949f590

=====
On Base (Base Sepolia) we run:

The native DYNEXA token (ERC-20).

The brand Company Registry.

The DynexaGiftToken contract (ERC-1155) for all multi-brand GiftTokens.

The QuestRewards contract, which uses those contracts to pay rewards to users when they complete missions coordinated via XMTP.

CDP Embedded Wallets and Coinbase Pay live in the frontend/backend, but they interact with these contracts on Base.

