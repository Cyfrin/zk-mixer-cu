// withdraw.nr
use std::hash::poseidon2;
mod merkle_tree;

fn main(
        // Public inputs
        root: pub Field,
        nullifier_hash: pub Field,
        recipient: pub Field,
        // Private inputs
        nullifier: Field,
        secret: Field,
        merkle_proof: [Field; 20],
        proof_is_right: [bool; 20]) {
    // Compute the commitment: commitment = Poseidon2(nullifier, secret) to check it against the Merkle tree
    let commitment: Field = poseidon2::Poseidon2::hash([nullifier, secret], 2); // hash the two elements in the array

    // Compute nullifier hash: nullifier_hash = MiMC(nullifier)
    let computed_nullifier_hash: Field = poseidon2::Poseidon2::hash([nullifier], 1); // hash the nullifier
    assert(computed_nullifier_hash == nullifier_hash);

    // Verify Merkle path
    let computed_root: Field = merkle_tree::compute_merkle_root(commitment, merkle_proof, proof_is_right);
    assert(computed_root == root);

    // Bind public inputs to the ZK proof
    let _recipient_binding = recipient * recipient;
}

// #[test]
// fun test_main() {
//     // Test the main function with dummy values
//     // let root = Field::from(123456789);
//     // let nullifier_hash = Field::from(987654321);
//     // let recipient = Field::from(111111111);
//     // let nullifier = Field::from(222222222);
//     // let secret = Field::from(333333333);
//     // let merkle_proof: [Field; 20] = [Field::from(i as u64); 20];
//     // let proof_is_right: [bool; 20] = [true; 20];

//     main(root, nullifier_hash, recipient, nullifier, secret, merkle_proof, proof_is_right);
// }