# Synapse Agent Hub

A decentralized autonomous agent trading hub built on Stacks (Clarity smart contracts). This platform enables agents to register, stake STX, execute trades, and earn profits in a trustless environment.

## Overview

**Synapse Agent Hub** is a smart contract-based system that manages autonomous trading agents on the Stacks blockchain. Agents register with a minimum stake, execute trades, and have their performance tracked on-chain.

### Key Features

- **Agent Registration**: Agents stake STX to register and participate
- **Trade Execution**: Execute buy/sell trades with automatic fee collection
- **Performance Tracking**: On-chain profit/loss and trade count metrics
- **Admin Controls**: Configurable minimum stake, trade fees, and stake slashing
- **Stake Management**: Agents can deactivate and withdraw their stake

## Contract Details

| Component | Value |
|-----------|-------|
| **Minimum Stake** | 0.1 STX (100,000 µSTX) |
| **Trade Fee** | 0.0005 STX (500 µSTX) |
| **Network** | Stacks (Clarity) |

## Core Functions

### Admin Functions
- `set-admin(new-admin)` — Transfer admin privileges
- `set-min-stake(amount)` — Update minimum registration stake
- `set-trade-fee(fee)` — Adjust per-trade fee

### Agent Management
- `register-agent()` — Register as a trading agent
- `deactivate-agent(agent-id)` — Deactivate and withdraw stake
- `execute-trade(agent-id, side, amount, profit)` — Record a trade

### Read-Only
- `get-agent(agent-id)` — Fetch agent details
- `get-agent-by-owner-read(owner)` — Look up agent by owner
- `get-config()` — View current configuration
| 106 | Unauthorized |

## Project Structure
