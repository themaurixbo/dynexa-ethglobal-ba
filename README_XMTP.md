
# README_XMTP  

ETHGLOBAL AR 2025
Dynexa QuestBoard – XMTP Miniapp  

---

## 1. Overview

**Dynexa** is a Web3 rewards layer that lets brands launch gamified campaigns (quests, missions, GiftTokens, DYNEXA rewards) and users earn real, redeemable rewards onchain.

For **XMTP**, Dynexa builds **Dynexa QuestBoard**, a miniapp and agent that lives directly inside chat:

- Users join a group chat with friends or colleagues.  
- The Dynexa QuestBoard miniapp posts quests from brands and communities.  
- People accept quests, complete missions, and track leaderboards **without leaving the chat**.  
- Behind the scenes, an XMTP-based agent coordinates state and triggers onchain rewards for completed quests.

This turns XMTP into the **“social front door”** for Dynexa: awareness, engagement, and rewards are all driven through conversations.

---

## 2. XMTP Components Used

We focus on two key parts of the XMTP ecosystem:

1. **XMTP Miniapps**
   - A miniapp UI surface embedded inside chat.
   - Used to show:
     - Available quests in the current conversation.
     - Progress and status (joined, completed, pending reward).
     - Group leaderboard and total rewards earned.

2. **XMTP Agent SDK**
   - An off-chain agent that:
     - Listens to messages and miniapp actions in XMTP conversations.
     - Interprets commands like “join quest”, “complete quest”, etc.
     - Calls Dynexa backend APIs and onchain contracts to issue rewards.
   - Acts as the “brain” linking chat activity to actual reward transactions onchain.

---

## 3. Dynexa QuestBoard – User Experience

### 3.1 In-Chat Quests

In a group chat (friends, team, or community):

1. The group adds **Dynexa QuestBoard** to the conversation.  
2. The bot/miniapp posts a short message:

   > “New quest from Brand X: Buy any product this week and upload your receipt. Earn 50 DYNEXA and a GiftToken you can redeem for discounts.”

3. A button or miniapp tile appears:  
   - “View quest”, “Join quest”, “See leaderboard”.

### 3.2 Joining and Completing Quests

When a user interacts with the miniapp:

1. They open the miniapp panel and see:
   - Quest description,
   - Conditions (deadline, actions required),
   - Reward (DYNEXA, GiftTokens, discounts, etc.).

2. They tap **“Join quest”**:
   - The miniapp sends an XMTP message/interaction.
   - The **XMTP agent** receives and logs:
     - Conversation id,
     - User identity,
     - Quest id,
     - Timestamp.

3. When the user completes the action (for example):
   - “Upload receipt”, “Connect purchase proof”, “Finish a mission in the Dynexa app”, etc.,
   - The Dynexa backend validates the completion and notifies the XMTP agent.

4. The agent then:
   - Sends a confirmation message to the XMTP group:
     - “@alice just completed Quest X and earned 50 DYNEXA 🎉”
   - Triggers onchain reward issuance (see section 4).

### 3.3 Group Leaderboards & Social Proof

The miniapp offers a **leaderboard view** for the current conversation:

- Shows:
  - Participants,
  - Points earned,
  - Quests completed,
  - Total onchain rewards.
- Updates in near real time when the agent detects new completions.
- Encourages friendly competition and keeps the group engaged with the brand.

---

## 4. Onchain Rewards Triggered from XMTP

Dynexa QuestBoard is not “just a game in chat”; it issues **real, onchain rewards**.

### 4.1 Integration with Dynexa Protocol

When the XMTP agent confirms a quest completion:

1. It calls Dynexa’s backend with:
   - `userId / wallet address`,
   - `questId`,
   - `campaignId`,
   - group metadata if relevant.

2. The backend validates:
   - The quest rules,
   - Whether the user already claimed,
   - Any anti-abuse checks.

3. If valid, the backend or a server wallet calls Dynexa’s onchain contracts on Base (or the chosen chain):

- `DynexaRewardEngine.mintReward(userWallet, rewardType, amount)`  
- Or:
  - Mint a **DYNEXA** ERC-20 reward,  
  - Mint a **GiftToken** ERC-1155 / ERC-721 representing a voucher or item.

4. The XMTP agent then posts back to the chat:
   - A message like:
     - “Reward sent! Tx: 0x1234… You just earned a GiftToken for 15% off at Brand X.”

This closes the loop: **chat → action → onchain reward → social proof back in chat.**

---

## 5. Architecture

### 5.1 Components

- **XMTP Client / Miniapp (Frontend)**
  - Renders:
    - Quest list and quest detail.
    - Join / complete buttons.
    - Leaderboard view.
  - Sends miniapp actions and messages to the XMTP network.

- **XMTP Agent (Backend service)**
  - Listens for:
    - Quest join requests,
    - Completion confirmations,
    - Miniapp interaction events.
  - Keeps per-conversation state in a small database:
    - Users, quests, completion status, points.
  - Calls Dynexa backend and/or onchain contracts.

- **Dynexa Backend**
  - Global source of truth for:
    - Brands,
    - Campaigns,
    - Quests,
    - Reward parameters.
  - Exposes APIs to:
    - Validate quest completion,
    - Trigger onchain reward mints,
    - Retrieve aggregate stats for leaderboards.

- **Dynexa Onchain Contracts**
  - `DynexaRewardEngine`: issues DYNEXA and GiftTokens.  
  - `DynexaCompanyTreasury`: tracks brand-funded budgets.  
  - Other Dynexa protocol contracts that define how rewards can be redeemed.

---

### 5.2 Group State Without Native Group APIs

XMTP miniapps do not (yet) provide a direct, built-in “group member list” for each miniapp.

To handle this, Dynexa uses a **hybrid approach**:

- The XMTP agent observes:
  - Which users send messages,
  - Who interacts with the miniapp in the conversation.
- It builds an inferred list of **“active quest participants”** for each conversation.
- It maintains group-level state on the backend:
  - `conversationId → [participantIds] → questProgress`.

This lets Dynexa:
- Compute leaderboards,
- Track progress,
- Avoid double-claiming rewards,
even without native “group members” APIs.

---

## 6. Developer Notes

### 6.1 Miniapp UI (Example)

The miniapp has a few core screens:

1. **Quest List**
   - All active quests in the current conversation.
2. **Quest Detail**
   - Description, rules, steps, reward preview.
3. **My Progress**
   - Which quests this user has joined and completed.
4. **Leaderboard**
   - Ranking of participants in this chat by quests completed / points.

### 6.2 Agent Flows

Key agent functions (conceptual):

- `onMiniappAction("joinQuest", user, conversationId, questId)`  
- `onMiniappAction("viewLeaderboard", user, conversationId)`  
- `onBackendWebhook("questCompleted", userId, questId)`  

For `questCompleted`:
- The agent:
  - Updates internal state,
  - Calls Dynexa reward issuance,
  - Sends a message to the XMTP conversation announcing the reward.

---

## 7. Why XMTP Matters for Dynexa

- **Awareness:** XMTP gives Dynexa a native, conversational surface — brands don’t just show banners, they talk to users in real time.  
- **Engagement:** Group quests and leaderboards turn simple promotions into collaborative, social experiences.  
- **Conversion:** Every completed quest is tied directly to **onchain rewards**, managed by Dynexa’s protocol.

For XMTP, Dynexa is a strong example of:

> “Miniapps + agents + real onchain value” – not just stickers or notifications, but a full reward economy running from inside chat.

Dynexa QuestBoard shows how brands can:
- Reach users where they already are (in conversations),
- Drive measurable actions (quests),
- And deliver real, composable, onchain rewards — all powered by XMTP.
