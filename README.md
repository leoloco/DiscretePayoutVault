# DiscretePayoutVault

The **DiscretePayoutVault** is a Solidity-based smart contract for managing deposits, minting shares, and distributing proceeds proportionally to users' shareholdings. This contract is designed to handle discrete (non-continuous) payouts, ensuring a fair and transparent mechanism for proceeds distribution.

## Features

- **Deposit & Withdrawal**: Users can deposit USD tokens into the vault and receive an equivalent amount of shares at a 1:1 ratio. Shares represent their stake in the vault.
- **Discrete Proceeds Distribution**: Proceeds can be distributed to all shareholders proportionally, based on their shareholdings at the time of distribution.
- **Claim Proceeds**: Users can claim their share of the distributed proceeds at any time.
- **Multi-Round Proceeds**: The contract supports multiple rounds of proceeds distribution, ensuring non-dilution of the proceeds.

---

## How It Works

1. Users deposit USD tokens into the vault, receiving a 1:1 equivalent in shares.
2. Proceeds (e.g., profits or rewards) are distributed by the vault owner to all shareholders proportionally to their holdings at the time of distribution.
3. Users can claim their share of the distributed proceeds at any time.
4. Users can withdraw their initial deposit along with any unclaimed proceeds.

---

## Smart Contracts

- **UsdToken**: A mock ERC20 token used for testing purposes.
- **DiscretePayoutVault**: The main contract that manages deposits, proceeds distribution, and withdrawals.

---

## Setup Instructions

1. Clone the repository and navigate to the project directory:

   ```bash
   git clone <repository-url>
   cd <project-directory>
   ```

2. Install dependencies using Foundry:

    ```bash
    forge install
    ```

3. Compile the smart contracts:

    ```bash
    forge build
    ```
## Running Tests

The project uses Foundry for testing. The test suite is located in the test directory and includes comprehensive test cases for all functionalities of the DiscretePayoutVault.

To run the tests:

```bash
forge test
```

## License

This project is licensed under the MIT License. See the LICENSE file for more details.
