
# README_FLARE  
ETHGLOBAL AR 2025

Dynexa Yield Engine on Flare  

---

## 1. Overview

**Dynexa** is a Web3 rewards layer that turns brand marketing budgets into on-chain, gamified rewards for users (quests, missions, GiftTokens, and the DYNEXA coin).

On **Flare**, Dynexa runs a dedicated **Yield Engine** that:

- Aggregates capital from multiple brands into a **shared treasury** on Flare.  
- Generates **two types of native yield**:
  1. **FLR FTSO delegation yield** (low-risk, protocol-native).  
  2. **DeFi yield using FXRP / XRPFI vaults** (higher-yield, managed risk).  
- Converts this yield into a **subsidy pool** that finances extra rewards, quests, and campaigns in Dynexa — without brands ever touching DeFi directly. Also this is on of the incomes for Dynexa

Flare is not “just a price feed” here; it is the **core yield and data layer** underneath Dynexa’s loyalty ecosystem.

---

## 2. Flare Protocols Used

We explicitly leverage Flare’s **enshrined data protocols** and native features:

### 2.1 FAssets / FXRP + State Connector

- We use the **FAssets system** to mint **FXRP** from XRP held on XRPL:
  - Dynexa sends XRP from its XRPL treasury wallet to an FAssets Agent.
  - Flare’s **State Connector** verifies the XRPL payment.
  - The FXRP **AssetManager** contract mints **FXRP** 1:1 on Flare to Dynexa’s EVM address.
- Result: brand marketing budgets can be transformed (off-chain) into XRP, then **on-chain into FXRP**, which becomes productive capital in Flare DeFi (XRPFI, vaults, etc.).

### 2.2 FTSO (Flare Time Series Oracle)

- We use **FTSO** in two ways:
  1. **Yield source** – Dynexa delegates part of its FLR to FTSO providers and shares in the FLR rewards they receive for delivering high-quality price data.  
  2. **Risk & valuation** – Dynexa reads FLR/XRP prices from FTSO to:
     - Value treasury holdings in USD terms.
     - Enforce **price-aware risk limits** (max allocation caps, price floors, drawdown thresholds).


---

## 3. Yield Architecture

Dynexa’s Flare Yield Engine has **two main yield paths**:

1. **FTSO Delegation Yield (FLR)**  
   - Treasury FLR is delegated to a set of FTSO providers.  
   - Rewards paid in FLR are periodically claimed and tracked as `accumulatedFtsoYieldFLR`.

2. **DeFi Yield (FXRP / XRPFI, optionally FLR)**  
   - Treasury capital is converted to XRP off-chain, then minted as **FXRP** via FAssets on Flare.  
   - FXRP is deposited into XRPFI / Firelight-style vaults or other DeFi strategies.  
   - The vault’s value grows over time; the delta between current value and principal is `accumulatedDefiYieldFXRP`.

**Key principle**:  
Brands **never** interact with these strategies directly. They only see a higher reward capacity in Dynexa. The full complexity of FTSO and XRPFI is hidden behind Dynexa’s treasury contracts.

---

## 4. Smart Contract Suite

Below is the contract suite dedicated to Flare.

### 4.1 `DynexaFlareTreasury`

**Purpose**  
Core vault on Flare that holds FLR and FXRP, tracks allocations and yield for both FTSO and DeFi strategies.

**Responsibilities**

- Store FLR and FXRP that belong to the Dynexa protocol.  
- Track allocations:
  - Idle FLR / FXRP (not in yield).  
  - FLR delegated via FTSO.  
  - FXRP deposited in DeFi vaults.  
- Track accumulated yield:
  - `accumulatedFtsoYieldFLR`.  
  - `accumulatedDefiYieldFXRP`.

**Key state (example)**

```solidity
IERC20 public FLR;   // wrapped FLR representation if needed
IERC20 public FXRP;  // FAsset token

uint256 public principalFLR;
uint256 public idleFLR;
uint256 public ftsoDelegatedFLR;

uint256 public principalFXRP;
uint256 public stakedFXRP;

uint256 public accumulatedFtsoYieldFLR;
uint256 public accumulatedDefiYieldFXRP;

address public xrpfVault; // XRPFI / Firelight vault address
```

**Core functions (sketch)**

- Deposits / withdrawals:
  - `depositFLR(uint256 amount)`  
  - `withdrawFLR(uint256 amount)`  
  - `depositFXRP(uint256 amount)`  
  - `withdrawFXRP(uint256 amount)`

- DeFi staking:
  - `stakeToVault(uint256 amount)`  
  - `harvestDefiYield()`

- View helpers:
  - `getVaultValueFXRP()`  
  - `getTotalTreasuryValueUSD()` (optionally via FTSO).

**Roles**

- `TREASURY_ROLE` – deposit/withdraw.  
- `STRATEGY_ROLE` – FTSO/DeFi allocations.  
- `DEFAULT_ADMIN_ROLE` – governance / multisig.

---

### 4.2 `DynexaYieldConfig`

**Purpose**  
Central registry of risk parameters and allocation caps, with timelock for changes.

**Key parameters**

```solidity
uint16 public maxFtsoAllocationBps;   // e.g. 5000 = 50% of treasury
uint16 public maxDefiAllocationBps;   // e.g. 4000 = 40%
uint16 public minLiquidBufferBps;     // e.g. 3000 = 30% liquid

struct AssetRiskConfig {
    int256 priceFloor;       // micro-USD or similar
    int256 priceWarning;     // soft threshold
    uint16 maxDrawdownBps;   // e.g. 3000 = 30%
}

AssetRiskConfig public xrpRisk;
AssetRiskConfig public flrRisk;

uint256 public configChangeDelay; // seconds
```

**Mechanism**

- Changes are **proposed**, then **executed after `configChangeDelay`**:
  - `proposeConfigChange(...)`  
  - `executeConfigChange(...)`

This prevents instant, arbitrary changes to core risk limits.

---

### 4.3 `DynexaFTSOManager`

**Purpose**  
Encapsulate FTSO delegation logic and yield accounting. For testing purposses the delegation address is ours.

**Key structures**

```solidity
struct ProviderInfo {
    address provider;
    uint16 weightBps; // sum of weights = 10000
}

ProviderInfo[] public ftsoProviders;
uint256 public lastDelegationTimestamp;
```

**Responsibilities**

- Keep a list of approved FTSO providers and their weights.  
- Delegate FLR across providers according to weights.  
- Claim FLR rewards from FTSO and forward them to `DynexaFlareTreasury`, updating `accumulatedFtsoYieldFLR`.

(Exact function signatures depend on Flare’s current FTSO delegation APIs.)

---

### 4.4 `DynexaXRPFIManager`

**Purpose**  
Isolate interaction with XRPFI / Firelight-style DeFi vaults for FXRP (and optionally FLR).

**Key variables**

```solidity
IERC20 public FXRP;
address public vault; // XRPFI / Firelight vault address
```

**Responsibilities**

- Approve and deposit FXRP into the vault.  
- Withdraw principal / yield when needed.  
- Expose vault balance to the treasury.

**Example functions**

- `stakeFXRP(uint256 amount)`  
- `withdrawFXRP(uint256 amount)`  
- `getVaultBalance() external view returns (uint256)`

This logic can live here or directly inside `DynexaFlareTreasury`.

---

### 4.5 `DynexaSubsidyEngine` (optional but powerful)

**Purpose**  
Translate yield (FLR/FXRP) into **subsidy units** for brands and campaigns.

**Responsibilities**

- Read `accumulatedFtsoYieldFLR` and `accumulatedDefiYieldFXRP` from the treasury.  
- Optionally read **brand activity data** via FDC (Web2Json):  
  `completedQuests`, `activeUsers`, etc.  
- Compute a share of the total yield per brand:

```solidity
mapping(uint256 => uint256) public companySubsidyUnits;
```

**Key functions**

 
- `recalculateSubsidies()` – recompute per-brand shares.  
- `consumeSubsidy(uint256 companyId, uint256 amount)` – called by Dynexa core when issuing extra rewards.

---

## 5. Yield Flows

### 5.1 FLR FTSO Delegation Flow

1. Dynexa acquires FLR off-chain and sends it to `DynexaFlareTreasury`.  
2. Treasury updates `principalFLR` and `idleFLR`.  
3. `DynexaFTSOManager` delegates FLR to a diversified set of FTSO providers.  
4. On each FTSO epoch:
   - Providers earn FLR rewards.  
   - Dynexa calls `claimFtsoRewards()` and receives FLR.  
   - Treasury updates `accumulatedFtsoYieldFLR += claimedAmount`.  
5. This yield can be:
   - Kept as FLR in the protocol treasury, or  
   - Converted into extra reward budget on the Dynexa side.

---

### 5.2 FXRP XRPFI / DeFi Flow

1. Brands fund Dynexa (fiat, USDC, XRP, FLR.).  
2. Dynexa converts a portion into **XRP** and sends it to its XRPL wallet.  
3. Using FAssets:
   - Call `reserveCollateral` on the FXRP AssetManager.  
   - Send XRP to the agent address with the payment reference.  
   - After State Connector verification, call `mint` to receive **FXRP** on Flare.  
4. FXRP is sent to `DynexaFlareTreasury`, updating `principalFXRP` and idle balances.  
5. `DynexaFlareTreasury` / `DynexaXRPFIManager`:
   - Approves and deposits FXRP into the XRPFI / Firelight vault.  
   - Updates `stakedFXRP` and marks principal.  
6. Periodically, `harvestDefiYield()`:
   - Reads current vault value.  
   - Computes `yield = currentValue - stakedFXRP`.  
   - Updates `accumulatedDefiYieldFXRP += yield`.  
7. FXRP yield can remain on Flare, be swapped, or mapped 1:1 as a **subsidy budget** for Dynexa rewards.

---

## 6. Risk & Security Model

**Protections**

1. **Allocation caps**
   - `maxFtsoAllocationBps` – cap for FTSO delegation.  
   - `maxDefiAllocationBps` – cap for DeFi allocations.  
   - `minLiquidBufferBps` – ensures a significant portion remains liquid/un-staked.

2. **Price-aware de-risking (FTSO data)**
   - Each asset (XRP, FLR) has an `AssetRiskConfig`:
     - `priceFloor`, `priceWarning`, `maxDrawdownBps`.  
   - If FTSO price < `priceFloor` or drawdown > `maxDrawdownBps`:
     - Block new XRPFI allocations.  
     - Optionally trigger partial withdrawals from vaults.  
     - Activate a `riskModeActive` flag until governance reviews.

3. **Timelocked risk parameter changes**
   - Any change to allocation caps or `AssetRiskConfig` is gated by `DynexaYieldConfig` with a **time delay**, allowing off-chain monitoring and review.

4. **Role separation**
   - `TREASURY_ROLE` – inflows/outflows.  
   - `STRATEGY_ROLE` – FTSO/DeFi allocation & harvesting.  
   - `RISK_ADMIN_ROLE` – risk configs.  
   - `GUARDIAN_ROLE` – pause in emergencies.  
   - `DEFAULT_ADMIN_ROLE` – top-level governance (multisig).

---

## 7. Why This Matters for Flare

Dynexa uses Flare not only as a data network but as a **real yield backbone for loyalty and marketing**:

- Brand budgets → XRP / FXRP / FLR on Flare.  
- FAssets + XRPFI + FTSO → real, protocol-native yield.  
- Risk-aware contracts → no blind speculation, clear protections.  
- Yield → **more and better rewards** for millions of end users.

From a Flare ecosystem perspective, Dynexa is a repeatable pattern:

> Take existing off-chain budgets (loyalty, marketing, rewards), pool them on Flare, turn them into yield, and feed that yield back into a Web3 user experience.

Dynexa becomes a **demand driver** for FLR, FXRP, FTSO and XRPFI, while giving brands and users a simple interface: more meaningful rewards, powered by Flare, without any DeFi complexity on their side.

CONTRACTS VERIFIED AND DEPLOYD EN TESTNET:

DynexaYieldConfig: 0xF69aAfbC325FD4E13Cb2ae05eCd79AC5Af463770
https://coston2-explorer.flare.network/address/0xf69aafbc325fd4e13cb2ae05ecd79ac5af463770

DynexaFlareTreasury: 0x5952CbB1719C11ce270AcA114E9328B0801013E1
https://coston2-explorer.flare.network/address/0x5952cbb1719c11ce270aca114e9328b0801013e1






