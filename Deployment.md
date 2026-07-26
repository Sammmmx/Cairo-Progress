# Messenger Contract

A Cairo/Starknet smart contract implementing message storage, a simple balance ledger, an allowance system, an owner-managed whitelist, and a basic auction state machine.

## Features

- **Messaging**: Owner-only `set_message` / public `get_message`, with a `MessageUpdated` event.
- **Balances**: `deposit` and `get_balance` (self-credited ledger).
- **Allowances**: `approve` and `get_allowance`, keyed by caller.
- **Whitelist**: Owner-only `add_to_whitelist`, indexed lookup via `get_whitelisted`.
- **Auction state**: Owner-only `set_status`, queried via `get_auction_status` (`NotStarted` / `Active` / `Ended`).
- Custom errors defined via a `MessengerError` enum, converted to `felt252` for use in `assert`.

## Prerequisites

Install the Cairo/Starknet toolchain on macOS:

# Scarb (Cairo build tool)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
```

# Starknet Foundry (sncast + snforge)
```bash
curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh
snfoundryup
```

## Create the project

Scaffold a new Scarb project (this creates the folder and names the package):

```bash
scarb new my_project_name
cd my_project_name
```

This generates `Scarb.toml` (with `name = "my_project_name"`) and a placeholder `src/lib.cairo` containing a default `HelloStarknet` contract.

Replace the contents of `src/lib.cairo` with your actual contract code, then save the file.

## Build

From the project root:

```bash
scarb build
```

This compiles `src/lib.cairo` and produces Sierra/CASM artifacts under `target/release/`.

## Set up an account

You need a funded Starknet account to pay declare/deploy fees on testnet (Sepolia).

1. Create an account:
   ```bash
   sncast account create --name my_account --network sepolia
   ```
   This prints an account address (not yet live on-chain).

2. Fund that address with Sepolia STRK — either from a [testnet faucet](https://starknet-faucet.vercel.app/) or by sending funds from another wallet to the printed address.

3. Confirm the balance arrived (STRK contract's `balanceOf`):
   ```bash
   sncast call \\
     --contract-address 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d \\
     --function balanceOf \\
     --calldata <YOUR_ACCOUNT_ADDRESS> \\
     --network sepolia
   ```

4. Deploy the account on-chain:
   ```bash
   sncast account deploy --name my_account --network sepolia
   ```

## Declare the contract

Registers your compiled contract class on-chain and returns a **class hash**:

```bash
sncast --account my_account declare --contract-name <CONTRACT_NAME> --network sepolia
```

`<CONTRACT_NAME>` must match the `contract_name` field from the artifacts JSON (e.g. `Messenger`), not the file name.

## Deploy the contract

Creates a live instance of the declared class at its own address. The constructor here takes no arguments:

```bash
sncast --account my_account deploy \\
  --class-hash <CLASS_HASH_FROM_DECLARE> \\
  --network sepolia
```

This returns a **contract address** — the live, callable instance.

## Verify

Check the contract on [Sepolia Voyager](https://sepolia.voyager.online):

```
https://sepolia.voyager.online/contract/<CONTRACT_ADDRESS>
```

Or call a view function directly:

```bash
sncast call \\
  --contract-address <CONTRACT_ADDRESS> \\
  --function get_auction_status \\
  --network sepolia
```

A fresh deployment should return `0x4e6f742053746172746564`, which decodes to `"Not Started"` — the constructor's initial `AuctionState`.

## Notes

- All owner-restricted functions (`set_message`, `add_to_whitelist`, `set_status`) require the caller to match the address that deployed the contract.
- `deposit` currently credits the caller's balance directly from the passed-in `amount` with no external token transfer — it's a ledger exercise, not an ERC-20 vault.
- Custom errors are defined in `MessengerError` and converted to `felt252` via an `Into` impl for use in `assert` calls.
