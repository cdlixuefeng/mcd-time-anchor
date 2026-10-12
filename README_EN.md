# 🍔⏳ mcd-time-anchor · McDonald's Time Anchor

> Order in one sentence, save money automatically, and turn your McDonald's history into a personal time archive.
>
> **"The usual."** — three words, and your optimal-price order is done.

A conversational ordering Skill built on [McDonald's China MCP Server](https://github.com/M-China/mcd-mcp-server). No GUI, no learning curve. Built for the **McDonald's Programmers' Day Creative Development Challenge**.

[中文版 README](README.md) · [Demo GIF](assets/demo-flow.gif)

![Full flow demo: the usual → order → reconcile → parallel universe](assets/demo-flow.gif)

> Watch a real round: say "the usual" → the Skill calls 4 MCP tools in the background and builds the optimal order → say "paid" → reconciled against the order API and written into your time archive → say "parallel universe" → cross-simulates alternatives from real anchors.

---

## What it is

Three core capabilities in one Skill.

### ⚡ The Usual (utility)

- **Order in one sentence**: "the usual" rebuilds your fixed combo into an optimal order — no menu browsing
- **Best coupon combination**: cross-checks all account coupons against store-available ones and computes the cheapest valid combination (real `calculate-price`, no guessing)
- **Personal notes carried over**: no ice, extra sauce — if it's in memory, it's in the order
- **Store routing**: "Chunxi Road" finds nearby stores with **zero external APIs**

### ⏳ Time Anchor (memory)

Every completed order settles into a **time anchor**: time, store, items, spend, savings — plus a scene snapshot (meal period / weather / place, depending on your setup tier).

> 📌 Your 3rd Spicy Chicken Burger combo this month, ¥4.5 cheaper than last time — a new coupon landed.
>
> 📌 Friday, 10 p.m. This is the 5th late-night order at this store.

The longer you use it, the more it becomes **your personal McDonald's time archive**.

### 🌌 Parallel Universe (the wild part)

Every anchor hides a fork in the road: the combination you didn't take, the coupon you didn't use, the other store. Say "parallel universe" and it cross-simulates:

> 🌌 **Price universe**: had you paid list price every time, this universe's you would have spent ¥92.1 more.
>
> 🌌 **Taste universe**: if you'd picked the alternative that was actually on the menu that day...
>
> 🌌 **Scene universe**: that rainy night (scene.weather=rain), had you chosen hot coffee instead of iced coke...
>
> 🌌 But this universe's you saved ¥51.5 and ate your comfort food 10 times. Other universes are fine. This one is real.

All deductions are marked **simulated** and computed from your real anchors. Nothing is fabricated.

### 🔧 Capability tiers

| | Base (default) | Enhanced (optional) |
|---|---|---|
| Requires | McDonald's MCP only | + AMap / Baidu Maps key (free tier) |
| Store routing | City / district / landmark keyword search | Precise geocoding + real distance ("200m from your office") |
| Scene awareness | Meal period | + Weather (rain → hot food, heatwave → iced drinks) |
| Parallel universe | Price / taste / store | + Scene dimension |

No key? Base tier runs fully.

---

## Quick start

### 0. Prerequisite: connect McDonald's MCP (one-time)

1. Visit [McDonald's MCP Open Platform](https://open.mcd.cn/mcp), log in with your phone number, activate and copy your MCP Token
2. Add `mcd-mcp` to your agent using [`mcp-config.example.json`](mcp-config.example.json), replacing `${MCD_MCP_TOKEN}` with your real Token

<details>
<summary><b>WorkBuddy example</b></summary>

Sidebar → Expert/Skills/Connectors → Connectors → Custom Connector → Configure MCP → paste the JSON → Save → Enable.
Other clients (Cursor / Trae / Cherry Studio / VSCode): see the [official platform guides](https://github.com/M-China/mcd-mcp-server#26-%E5%90%84%E5%B9%B3%E5%8F%B0%E6%8E%A5%E5%85%A5%E6%95%99%E7%A8%8B).

</details>

> ⚠️ Your Token is equivalent to account credentials. Keep it in your client config only — never in a file you commit or share.

Any MCP-capable agent works (protocol: Streamable HTTP).

### 1. Install the Skill

The Skill itself is a structured prompt — `skill/SKILL.md`:

- **Generic**: load `SKILL.md` as the agent's system prompt / custom instruction / skill file, and point its memory directory at `memory/` under this repo's `skill/`
- **WorkBuddy example**: import the `skill/` folder as a skill

### 2. (Optional) Enhanced tier

Register a free personal-tier key at [AMap](https://lbs.amap.com) or [Baidu Maps](https://lbsyun.baidu.com) and expose it to your agent as `AMAP_KEY` / `BAIDU_MAP_KEY` (either one). The Skill auto-detects and silently falls back to base tier if it's missing or invalid.

### 3. Set up your "usual"

During your first order, say: "remember this as my usual."

---

## 📊 Time archive viewer

`web/time-anchor-viewer.html` — zero-dependency single-file tool. **Double-click to open** (`file://`, no server, no external calls). Drop in your `memory/profile.json` and your archive becomes something you can see:

![Time archive viewer](assets/viewer-demo.png)

- **Your own archive**: pick or drag in `profile.json`
- **Demo**: open `web/time-anchor-viewer.html?demo=1` for built-in sample data
- **Renders**: stat cards (orders / paid / saved), parallel universe panel, anchor timeline, meal distribution, scene tags, filterable ledger
- **Privacy**: 100% local rendering, zero network requests

> Truth applies here too: `pending` and `cancelled` anchors are explicitly marked and **counted in no statistic**.

---

## How it works

```text
One sentence
   │
   ▼
┌──────────────────────────────────────────────┐
│  Skill (skill/SKILL.md)                       │
│  ① intent → ② memory read / write             │
│  ③ store routing (query-nearby-stores)        │
│  ④ menu & coupon check (query-meals / coupons)│
│  ⑤ best price (calculate-price)               │
│  ⑥ create order (create-order → pay link)     │
│  ⑦ reconcile (query-order) → anchor written   │
└──────────────────────────────────────────────┘
   │
   ▼
McDonald's MCP Server (https://mcp.mcd.cn)
```

Full tool list, call flows and verified interface details: [MCP_INTEGRATION.md](MCP_INTEGRATION.md).

---

## Repository layout

```text
mcd-time-anchor/
├── README.md / README_EN.md       # docs (CN / EN)
├── CONTEST_DECLARATION.md          # contest declaration (official, unmodified)
├── MCP_INTEGRATION.md              # MCP integration + full test log
├── mcp-config.example.json         # config sample (env-var placeholders only)
├── workbuddy.md                    # WorkBuddy development context
├── skill/SKILL.md                  # ⭐ the Skill: 6 flows + memory spec + red lines
├── web/time-anchor-viewer.html     # time archive viewer (double-click, ?demo=1)
├── demo/                           # animated demo page + sample dataset
├── docs/                           # contest issue template
├── assets/                         # screenshot & demo GIF
└── scripts/                        # dev tooling
```

---

## Privacy

- Anchors and preferences live **only in your local memory directory** (`memory/profile.json`)
- Never uploaded or synced; enhanced tier sends only location/city parameters — **never memory content**
- Delete the Skill and the memory is gone
- All config samples use environment-variable placeholders; no real credentials in this repo

---

## FAQ

**Can it pay for me?**
No. `create-order` returns the official payment link; you always complete payment at McDonald's official checkout. That's a safety boundary, not a limitation.

**Is the archive truthful?**
Yes. Every order is written as `pending` first, then reconciled against `query-order` on your next session (or when you say "paid"). Only genuinely paid orders are counted; cancelled or unpaid ones never enter the archive.

**Why conversational ordering over browsing the app myself?**
It saves taps and time — coupons, notes and store resolved in one go. Official app features and campaign info remain authoritative on McDonald's official channels.

---

## Contest notice

An entry for the McDonald's Programmers' Day Creative Development Challenge. Independently developed, not an official McDonald's product. Menu info, prices and availability follow real-time official results.

⭐ If this idea lands — ordering is the need, memory is the gift — drop a Star.
