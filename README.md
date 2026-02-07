# 🏢 Fractional NFT Real Estate MVP

Welcome to the **Fractional NFT Real Estate** project! 🚀 This Clarity smart contract platform allows for the tokenization of real estate properties into fractional shares, managed as **SIP-009 NFTs**. 🏘️✨

## 🌟 Features

- **Property Tokenization**: Create unique properties with a defined number of shares. 📝
- **Fractional Ownership**: Mint shares as non-fungible tokens (NFTs), each representing a piece of the property. 🧩
- **Dividend Distribution**: seamless support for depositing rental income or yields 💰.
- **Claim Mechanism**: Shareholders can easily claim their fair share of dividends at any time. 💸
- **Standard Compliant**: Fully implements the **SIP-009** NFT standard for interoperability with wallets and marketplaces. 🔗

## 🛠️ Usage

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed.
- A Stacks wallet or Devnet environment.

### deployment
1. **Initialize**: `clarinet new .` (Already done!)
2. **Check**: `clarinet check` to ensure everything is contract-valid. ✅
3. **Test/Console**: Run `clarinet console` to interact. 🕹️

### Contract Functions

#### 🏗️ Admin Functions
- `create-property (name, total-shares)`: Register a new real estate asset.
- `mint-share (property-id, recipient)`: Issue a share of the property to a user.
- `deposit-dividends (property-id, amount)`: Distribute STX earnings to all shareholders. 💵

#### 👤 User Functions
- `claim-dividends (token-id)`: Withdraw your pending earnings for a specific share. 🏧
- `transfer (token-id, sender, recipient)`: Sell or move your share. 🔄

#### 🔍 Read-Only
- `get-pending-dividends (token-id)`: Check how much you can claim.
- `get-property-details (property-id)`: View stats about a property.
- `get-owner (token-id)`: See who owns a share.

## 📜 Error Codes
- `u100`: Owner only (Unauthorized). 🚫
- `u101`: Not token owner. 🔐
- `u106`: Insufficient shares available. 📉
- `u108`: Nothing to claim. 🤷

---
*Built with ❤️ on Stacks*
