# ZK Mixer App

This app allows users to deposit assets and later withdraw them without linking the withdrawal to the deposit. It allows withdrawers to prove ownership of a deposit without revealing which deposit belongs to the withdrawer. 

## How it works

- Merkle tree for anonymity set:
    - Each deposit has its own _unique commitment_: hash of a secret plus public identifier
    - These commitmentsw are stored in a merkle tree (on-chain?)
    - The root of this Merkle tree is updated whenever a new deposit is made
- ZK proofs for withdrawals:
    - The withdrawer proves (using Noir) that they know a valid **preimage** for a commitment in the Merkle tree (without revealing which commitment they know)
    - The proof should also confirm that the commitment is part of a valid tree root without revealing which specific leaf they control.
    - To prevent double-spending, include a nullifier (a hash of the secret that gets recorded on-chain when withdrawn).

## How are ZKPs used in this app

Zero Knowledge Proofs (ZKPs) allow a prover to convince a verifier that a specific computation was correctly executed without requiring the verifier to rerun it. The proof ensures correctness without revealing the inputs used in the computation. The ‘zero-knowledge’ property means that the proof can be structured in a way that leaks no additional information beyond the validity of the computation itself.

### Notes

- We have removed paymasters to simplify the code. This means the receiving wallet will need to pay the gas fees therefore, hold native tokens

## Usage

### 1. Clone the repo

```bash
git clone https://github.com/Cyfrin/zk-mixer-cu.git
```

### 2. Install the dependencies

```bash
cd contracts && forge install
```

### 3. Running the tests

```bash
forge test
```

#### 4. (optional) re-creating the verifier

This step is needed if you modify the circuit logic at all.

1. Navigate inside the circuits folder and compile the circuit

```bash
nargo compile
```

2. Generate the verifiaction key

```bash
bb write_vk --oracle_hash keccak -b ./target/circuits.json -o ./target
```

3. Generate the verifier

```bash
bb write_solidity_verifier -k ./target/vk -o ./target/Verifier.sol
```

4. Delete your old `Verifier.sol` from inside `contracts/src` and replay with the new one!