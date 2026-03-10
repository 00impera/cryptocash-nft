# 🟢 CRYPTOCASH NFT — Monad Blockchain

> **On-chain NFT Banknotes · 20 Collectible Coins · Monad Network**  
> Mint · Swap · Collect — all in one cyberpunk-themed dApp

<p align="center">
  <img src="https://files.catbox.moe/r7791b.jfif" alt="CryptoCash NFT" width="300"/>
</p>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Live Features](#live-features)
- [Smart Contract](#smart-contract)
- [Wallet Connection](#wallet-connection)
- [NEAR Intents Swap](#near-intents-swap)
- [NFT Minting](#nft-minting)
- [20 Collectible Coins](#20-collectible-coins)
- [Tech Stack](#tech-stack)
- [File Structure](#file-structure)
- [How to Deploy](#how-to-deploy)
- [Support & Donate](#support--donate)

---

> ⚠️ **TO SHOW THE BANNER:** Save your `r7791b.jfif` image as `banner.png` and upload it to an `assets/` folder in this repo. GitHub will then display it perfectly at the top of this README.

---

## Overview

**CryptoCash NFT** is a fully on-chain dApp deployed on **Monad Mainnet (Chain ID: 143)**.  
Each NFT is a digital banknote featuring one of 20 real cryptocurrency symbols, rendered as an on-chain SVG.  
The app includes a built-in **cross-chain token swap** powered by NEAR Intents, so users can swap any token into MON before minting.

---

## Live Features

| Feature | Status | Description |
|---|---|---|
| 🟢 Wallet Connect | Live | MetaMask + any EVM wallet |
| 🟢 Free Mint | Live | 1x per wallet, no cost |
| 🟢 Paid Mint | Live | 0.001 MON, unlimited |
| 🟢 NEAR Intents Swap | Live | Cross-chain swap, 35+ chains |
| 🟢 Live Supply Counter | Live | Auto-refreshes every 30s |
| 🟢 Animated Hero Note | Live | Cycles through all 20 coins |
| 🟢 Transaction Explorer | Live | Direct link after mint |
| 🟢 Partner JWT | Live | cryptocash-nft, zero extra fees |

---

## Smart Contract

```
Network      : Monad Mainnet
Chain ID     : 143
RPC          : https://rpc.monad.xyz
Contract     : 0xf5C9cFfd9603a3aB3190B9cA02B9B7ceDc155Da2
Explorer     : https://explorer.monad.xyz/address/0xf5C9cFfd9603a3aB3190B9cA02B9B7ceDc155Da2
Standard     : ERC-721
Token Art    : On-chain SVG (no IPFS)
```

### ABI Functions Used

| Function | Type | Description |
|---|---|---|
| `mint()` | `payable` | Paid mint — costs 0.001 MON |
| `firstFreeMint()` | `external` | Free mint — 1x per wallet address |
| `totalSupply()` | `view` | Returns total NFTs minted so far |
| `hasFreeMinted(address)` | `view` | Returns true if wallet already used free mint |

---

## Wallet Connection

### Supported Wallets
- 🦊 **MetaMask** — detected via `window.ethereum`
- 🐰 **Rabby** — detected via `window.ethereum.isRabby`
- 🔵 **Coinbase Wallet** — detected via `window.ethereum.isCoinbaseWallet`
- 🔗 **Any EVM Wallet** — generic `window.ethereum` fallback

### Auto Network Switch
When a wallet connects, the app automatically:
1. Requests `eth_requestAccounts` to get the user address
2. Calls `wallet_switchEthereumChain` to switch to Monad (chainId `0x8F`)
3. If Monad is not in the wallet yet, calls `wallet_addEthereumChain` to add it automatically
4. Initialises ethers.js `Web3Provider` + `Signer`
5. Checks `hasFreeMinted()` on-chain — disables free option if already used

### Account Change Handling
- Listens to `accountsChanged` event — updates wallet state live without page reload
- Disconnecting clears wallet, signer, and contract instance

---

## NEAR Intents Swap

The swap panel uses the **NEAR Intents 1-Click API** (`https://1click.chaindefuser.com`) for real cross-chain, non-custodial token swaps.

### Partner Configuration
```
JWT Partner ID : cryptocash-nft
Extra Fee      : 0% (waived via partner JWT)
Routing        : Priority
JWT Expires    : 2026
```

### Supported Tokens

| Symbol | Network | Type | Asset ID |
|---|---|---|---|
| ETH | Ethereum | Native | `nep141:eth.omft.near` |
| BTC | Bitcoin | Native | `nep141:btc.omft.near` |
| USDC | Ethereum | ERC-20 | `nep141:eth-0xa0b8...omft.near` |
| USDT | Ethereum | ERC-20 | `nep141:eth-0xdac1...omft.near` |
| SOL | Solana | Native | `nep141:sol.omft.near` |
| NEAR | NEAR | NEP-141 | `nep141:wrap.near` |
| MON | Monad | Native | `nep141:monad-0x000...omft.near` |
| BNB | BSC | Native | `nep141:bsc-0x000...omft.near` |
| USDC | Base | ERC-20 | `nep141:base-0x833...omft.near` |

### Swap Flow — Step by Step

```
1. User enters amount + selects FROM / TO tokens
2. App calls POST /v0/quote with:
   - swapType: EXACT_INPUT
   - originAsset / destinationAsset
   - amount (in smallest units, BigInt)
   - slippageTolerance: 100 (= 1%)
   - dry: false  ← required to get real depositAddress
   - deadline: 5 minutes from now
3. API returns:
   - amountOut (estimated output)
   - minAmountOut (with slippage)
   - depositAddress (unique address for this swap)
   - depositMemo (optional, required for some chains)
   - timeEstimate (seconds)
4. App shows deposit address — user clicks EXECUTE SWAP
5. Wallet auto-switches to the origin chain
6. For native coins (ETH, MON, BNB):
   → eth_sendTransaction to depositAddress, value = amountRaw
7. For ERC-20 tokens (USDC, USDT):
   → Encode transfer(address,uint256) with selector 0xa9059cbb
   → eth_sendTransaction to tokenContract
8. App notifies NEAR Intents via POST /v0/deposit (speeds detection)
9. App polls GET /v0/status/{depositAddress} every 5 seconds
10. Status transitions:
    PENDING_DEPOSIT → PROCESSING → SUCCESS ✅
                                 → REFUNDED ↩
                                 → FAILED ❌
```

### Status Polling States

| Status | Meaning |
|---|---|
| `PENDING_DEPOSIT` | Waiting for on-chain confirmation of deposit |
| `PROCESSING` | Market makers competing to fill the order |
| `SUCCESS` | Tokens delivered to destination wallet |
| `REFUNDED` | Swap failed — original tokens returned |
| `FAILED` | Unrecoverable error |
| `INCOMPLETE_DEPOSIT` | User sent less than the required minimum |

### Non-EVM Chains
For **Bitcoin**, **Solana**, and **NEAR** as the source token, the app cannot sign via MetaMask. Instead it displays the deposit address and memo for manual transfer, then starts polling automatically.

### Chain Switching
```
Ethereum  → chainId 0x1
Base      → chainId 0x2105
BSC       → chainId 0x38
Monad     → chainId 0x8F
```

---

## NFT Minting

### Options

| Option | Cost | Limit | Function |
|---|---|---|---|
| 🎁 Free Mint | 0 MON | 1x per wallet | `firstFreeMint()` |
| 💎 Paid Mint | 0.001 MON | Unlimited | `mint()` |

### Mint Flow
1. Connect wallet → auto-switches to Monad Mainnet
2. Select **Free** or **Paid** option
3. Click **MINT NOW** → MetaMask confirmation popup
4. Transaction submitted → app waits for `tx.wait()`
5. On confirmation: success message + direct Explorer link
6. Supply counter auto-updates

### Free Mint Check
On wallet connect, `hasFreeMinted(address)` is called automatically:
- If `true` → Free option is greyed out with label "Already used"
- App auto-selects Paid option

---

## Animated Hero Banner

The floating NFT banknote on the hero section:
- Cycles through all **20 coin symbols** every 2 seconds
- Each coin shows its own color and glow effect
- CSS `@keyframes float` — gentle up/down + tilt animation
- Timestamp updates every second showing live UTC time

---

## Live Supply Counter

```javascript
// Calls totalSupply() on Monad RPC every 30 seconds
// Updates both the nav bar and the stats panel
setInterval(loadSupply, 30000);
```

No wallet connection required — reads directly from Monad RPC via ethers.js `JsonRpcProvider`.

---

## 20 Collectible Coins

| # | Symbol | Name | Color |
|---|---|---|---|
| 1 | BTC | Bitcoin | #F7931A |
| 2 | ETH | Ethereum | #627EEA |
| 3 | USDT | Tether | #26A17B |
| 4 | BNB | BNB | #F3BA2F |
| 5 | SOL | Solana | #9945FF |
| 6 | XRP | XRP | #00AAE4 |
| 7 | USDC | USD Coin | #2775CA |
| 8 | DOGE | Dogecoin | #C2A633 |
| 9 | ADA | Cardano | #0033AD |
| 10 | AVAX | Avalanche | #E84142 |
| 11 | DOT | Polkadot | #E6007A |
| 12 | LINK | Chainlink | #375BD2 |
| 13 | MATIC | Polygon | #8247E5 |
| 14 | LTC | Litecoin | #BFBBBB |
| 15 | SHIB | Shiba Inu | #FFA409 |
| 16 | UNI | Uniswap | #FF007A |
| 17 | XLM | Stellar | #7D00FF |
| 18 | XMR | Monero | #FF6600 |
| 19 | TRX | Tron | #EF0027 |
| 20 | ATOM | Cosmos | #6F4E7C |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Blockchain | Monad Mainnet (EVM-compatible) |
| NFT Standard | ERC-721 |
| Token Art | On-chain SVG (no IPFS dependency) |
| Web3 Library | ethers.js v5.7.2 |
| Cross-chain Swap | NEAR Intents 1-Click API |
| Frontend | Vanilla HTML + CSS + JavaScript |
| Fonts | Orbitron (headers) + Share Tech Mono (body) |
| Styling | Pure CSS — no frameworks |

---

## File Structure

```
cryptocash-nft/
├── index.html            ← Main mint page
├── README.md             ← This documentation
└── assets/
    └── banner.png        ← Banner image (upload your r7791b.jfif renamed as banner.png)
```

---

## How to Deploy

### GitHub Pages
```bash
git init
git add .
git commit -m "CryptoCash NFT dApp"
git remote add origin https://github.com/YOUR_USERNAME/cryptocash-nft.git
git push -u origin main
# Enable GitHub Pages: Settings → Pages → Deploy from branch: main
```

### Direct Hosting
- **GitHub Pages** — free, recommended
- **Vercel** — `vercel deploy`
- **Netlify** — drag and drop
- **IPFS** — fully decentralized

---

## 🔭 Track on Monad Vision

<p align="center">
  <a href="https://monadvision.com/myspace?feature=Watchlist">
    <img src="https://img.shields.io/badge/%F0%9F%94%AD%20MONAD%20VISION-OPEN%20WATCHLIST-%2339FF14?style=for-the-badge&labelColor=000000" alt="Monad Vision Watchlist">
  </a>
</p>

Add contract `0xf5C9cFfd9603a3aB3190B9cA02B9B7ceDc155Da2` to your watchlist to monitor:
- Live mint events · Transfer activity · Holder growth · On-chain analytics

---

## 💚 Support & Donate

<p align="center">
  <img src="./assets/banner.png" alt="CryptoCash NFT" width="80%">
</p>

<p align="center"><b>💚 Donate Address — Monad / EVM</b></p>

<p align="center">
  <code>0x592B35c8917eD36c39Ef73D0F5e92B0173560b2e</code>
</p>

> Send MON or any EVM-compatible token to the address above.  
> Every contribution helps keep the project alive. 🙏

---

<div align="center">

**CRYPTOCASH NFT · MONAD MAINNET · 2025**  
Built with 💚 for the Monad ecosystem

<br>

[![Contract](https://img.shields.io/badge/CONTRACT-0xf5C9...5Da2-%2339FF14?style=flat-square&labelColor=000)](https://explorer.monad.xyz/address/0xf5C9cFfd9603a3aB3190B9cA02B9B7ceDc155Da2)
[![Monad Vision](https://img.shields.io/badge/MONAD%20VISION-WATCHLIST-%2300C1DE?style=flat-square&labelColor=000)](https://monadvision.com/myspace?feature=Watchlist)
[![NEAR Intents](https://img.shields.io/badge/POWERED%20BY-NEAR%20INTENTS-%2300C1DE?style=flat-square&labelColor=000)](https://docs.near-intents.org)

</div>
