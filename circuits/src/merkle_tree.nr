// merkle_tree.nr
use std::hash::poseidon2;


// This module contains the Merkle tree logic for the withdraw circuit.
// It includes the computation of the Merkle root from a leaf and its path using the poseidon hash function.
pub fn compute_merkle_root(leaf: Field, merkle_proof: [Field; 20], proof_is_right: [bool; 20]) -> Field {
    let mut hash = leaf;
    for i in 0..20 {
        let sibling = merkle_proof[i];
        let is_right = proof_is_right[i];
        let (left, right) = if is_right {
            (sibling, hash)
        } else {
            (hash, sibling)
        };
        hash = poseidon2::Poseidon2::hash([left, right], 2); // hash is now the next level up!
    }
    hash
}
