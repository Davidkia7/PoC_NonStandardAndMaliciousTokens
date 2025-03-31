# PoC: Token Vulnerabilities in recoverERC20

This repository shows how certain tokens can cause problems in smart contracts like `Platformofmemecoins`, especially in its `recoverERC20` function. It includes two example tokens:

1. **`NonStandardToken.sol`**: A token that doesn’t follow the usual ERC-20 rules (it skips returning a "yes/no" signal), making recovery fail.
2. **`MaliciousToken.sol`**: A sneaky token that works once to send tokens, then blocks any further moves, locking them in the contract.

## What’s the Problem?
The `recoverERC20` function is meant to let the contract owner pull out tokens stuck in `Platformofmemecoins`. But it assumes all tokens play by the ERC-20 rules. If they don’t:
- **Non-Standard Tokens**: Cause errors because they don’t give the expected signal, stopping recovery.
- **Malicious Tokens**: Trap tokens by failing after the first transfer, wasting the owner’s gas and blocking access.

This doesn’t steal money directly, but it makes the recovery feature unreliable and frustrating.

## Why It Matters
- The owner can’t get stuck tokens out easily.
- It costs gas (transaction fees) for failed attempts.
- It might scare the owner from trying to recover other tokens.

## How to Test It (Step-by-Step)
You can try this PoC using [Remix IDE](https://remix.ethereum.org/), a free online tool. Here’s how to set it up and see the problem yourself.

### What You’ll Need
- A web browser to open Remix.
- No extra software—just use Remix’s built-in test environment.

### Steps to Run the PoC

#### 1. Open Remix and Add the Files
1. Go to [Remix IDE](https://remix.ethereum.org/).
2. In the left panel (File Explorer), click the "+" button to create three files:
   - `Platformofmemecoins.sol`
   - `NonStandardToken.sol`
   - `MaliciousToken.sol`
3. Copy and paste the code from each file in this repository into the matching file in Remix.

#### 2. Set Up the Target Contract (Platformofmemecoins)
1. **Compile**:
   - Go to the "Solidity Compiler" tab (hammer icon).
   - Select version `0.8.20`.
   - Click "Compile Platformofmemecoins.sol". Wait for a green checkmark.
2. **Deploy**:
   - Go to the "Deploy & Run Transactions" tab (play icon).
   - Choose `Platformofmemecoins` from the dropdown.
   - Fill in these details:
     - `name_`: `TestToken`
     - `symbol_`: `TTK`
     - `decimals_`: `18`
     - `initialBalance_`: `1000`
     - `tokenOwner`: Your Remix account (e.g., `0x5B38...`—copy from the "Account" dropdown).
     - `feeReceiver_`: Same as `tokenOwner`.
     - `Value`: Leave at `0`.
   - Click **Deploy**.
3. **Check**:
   - Find the deployed contract under "Deployed Contracts".
   - Click it, then call `owner()` to make sure it’s your address.
   - Copy the contract’s address (e.g., `0xTargetAddress`)—you’ll need it later.

#### 3. Set Up NonStandardToken
1. **Compile**:
   - In the "Solidity Compiler" tab, click "Compile NonStandardToken.sol".
2. **Deploy**:
   - In the "Deploy & Run Transactions" tab, select `NonStandardToken`.
   - Enter `initialSupply`: `1000`.
   - Click **Deploy**.
3. **Check**:
   - Expand the deployed contract.
   - Call `balanceOf` with your address (e.g., `0x5B38...`)—you should see `1000000000000000000000` (1000 tokens).
   - Copy the contract address (e.g., `0xNonStandardAddress`).

#### 4. Set Up MaliciousToken
1. **Compile**:
   - Compile `MaliciousToken.sol`.
2. **Deploy**:
   - Select `MaliciousToken`.
   - Enter `initialSupply`: `1000`.
   - Click **Deploy**.
3. **Check**:
   - Call `balanceOf` with your address—should show `1000000000000000000000` (1000 tokens).
   - Copy the contract address (e.g., `0xMaliciousAddress`).

#### 5. Send Tokens to Platformofmemecoins
- **NonStandardToken**:
  1. Select the `NonStandardToken` contract under "Deployed Contracts".
  2. Call `transfer`:
     - `recipient`: Paste `0xTargetAddress`.
     - `amount`: `100000000000000000000` (100 tokens—type it exactly like this).
     - Click **transact**.
  3. Check: Call `balanceOf(0xTargetAddress)` on `NonStandardToken`—should show `100000000000000000000`.
- **MaliciousToken**:
  1. Select the `MaliciousToken` contract.
  2. Call `transfer`:
     - `recipient`: `0xTargetAddress`.
     - `amount`: `100000000000000000000` (100 tokens).
     - Click **transact**.
  3. Check: Call `balanceOf(0xTargetAddress)` on `MaliciousToken`—should show `100000000000000000000`.

#### 6. Try Recovering the Tokens
- **Use Platformofmemecoins**:
  1. Go back to the `Platformofmemecoins` contract under "Deployed Contracts".
  2. Make sure your account (e.g., `0x5B38...`) is selected—it’s the owner.
- **Recover NonStandardToken**:
  1. Call `recoverERC20`:
     - `tokenAddress`: Paste `0xNonStandardAddress`.
     - `tokenAmount`: `100000000000000000000` (100 tokens).
     - Click **transact**.
  2. Look at the bottom "Terminal" panel—it’ll show an error like `"execution reverted"`.
- **Recover MaliciousToken**:
  1. Call `recoverERC20`:
     - `tokenAddress`: `0xMaliciousAddress`.
     - `tokenAmount`: `100000000000000000000` (100 tokens).
     - Click **transact**.
  2. Check the Terminal—expect an error like `"Malicious token: Transfer disabled after initial transfer"`.

#### 7. See What Happened
- **NonStandardToken**: Recovery fails because it doesn’t send back a "yes/no" signal, confusing the contract.
- **MaliciousToken**: Recovery fails because the token blocks it after the first move, trapping it.
- **Check Again**:
  - Call `balanceOf(0xTargetAddress)` on both tokens—tokens are still there, not recovered.
  - Your gas (fake Remix ETH) gets used up, but nothing moves.

## What This Shows
- **Non-Standard Tokens**: Mess up recovery because they don’t follow the rules.
- **Malicious Tokens**: Lock tokens on purpose, wasting your time and gas.
- It’s not about stealing—it’s about breaking the system’s trust and usefulness.

## How to Fix It
Change `recoverERC20` to handle weird tokens better:
```solidity
function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
    uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
    require(balance >= tokenAmount, "Not enough tokens");
    (bool success, ) = tokenAddress.call(
        abi.encodeWithSelector(IERC20.transfer.selector, owner(), tokenAmount)
    );
    if (!success) {
        emit RecoveryFailed(tokenAddress, tokenAmount);
    }
}
event RecoveryFailed(address indexed tokenAddress, uint256 amount);
