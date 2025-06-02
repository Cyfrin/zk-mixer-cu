# ZK Mixer App

This app allows users to deposit assets and later withdraw them without linking the withdrawal to the deposit. It allows withdrawers to prove ownership of a deposit without revealing which deposit belongs to the withdrawer. 

## How it works

- Merkle tree for anonymity set:
    - Each deposit has its own _unique commitment_: hash of a secret plus public identifier
    - These commitmentsw are stored in a merkle tree (on-chain?)
    - The root of this Merkle tree is updated whenever a new deposit is made
- ZK proofs for withdrawals:
    - The withdrawer proves (using Noir) that they know a valid **preimage** for a commitmnebnt in the Merkle tree (without revealing which commitment they know)
    - The proof should also confirm that the commitment is part of a valid tree root without revealing which specific leaf they control.
    - To prevent double-spending, include a nullifier (a hash of the secret that gets recorded on-chain when withdrawn).

## How are ZKPs used in this app

Zero Knowledge Proofs (ZKPs) allow a prover to convince a verifier that a specific computation was correctly executed without requiring the verifier to rerun it. The proof ensures correctness without revealing the inputs used in the computation. The ‘zero-knowledge’ property means that the proof can be structured in a way that leaks no additional information beyond the validity of the computation itself.

### Notes

- We have removed paymasters to simplify the code. This means the receiving wallet will need to pay the gas fees therefore, hold native tokens
