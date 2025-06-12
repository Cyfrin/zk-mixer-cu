// SPDX-License-Identifier: MIT
/**
 * @title Mixer (Educational Adaptation of Tornado Cash)
 * @notice This smart contract is a simplified and modified version of the Tornado Cash protocol,
 *         developed purely for educational purposes as part of a blockchain development course.
 * @dev The original design and cryptographic structure are inspired by Tornado Cash:
 *      https://github.com/tornadocash/tornado-core
 *
 * @author Cyfrin
 * @notice Do not deploy this contract to mainnet or use it for handling real funds.
 *         This contract is unaudited and intended for demonstration only.
 */

pragma solidity ^0.8.24;

import {IVerifier} from "./Verifier.sol";
import {IncrementalMerkleTree, Poseidon2} from "./IncrementalMerkleTree.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Mixer is IncrementalMerkleTree, ReentrancyGuard {
    IVerifier public immutable i_verifier; // Noir generated i_verifier contract
    uint256 public DENOMINATION = 0.001 ether; // the fixed amount of ETH that needs to be sent of the Mixer contract

    mapping(bytes32 => bool) public s_nullifierHashes; // used nullifiers to prevent double spending
    mapping(bytes32 => bool) public s_commitments; // we store all commitments just to prevent accidental deposits with the same commitment

    event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
    event Withdrawal(address to, bytes32 nullifierHash);

    error Mixer__DepositValueMismatch(uint256 expected, uint256 actual);
    error Mixer__PaymentFailed(address recipient, uint256 amount);
    error Mixer__NoteAlreadySpent(bytes32 nullifierHash);
    error Mixer__UnknownRoot(bytes32 root);
    error Mixer__InvalidWithdrawProof();
    error Mixer__FeeExceedsDepositValue(uint256 expected, uint256 actual);
    error Mixer__CommitmentAlreadyAdded(bytes32 commitment);
    /**
     * @dev The constructor
     * @param _verifier the address of SNARK verifier for this contract
     * @param _hasher the address of MiMC hash contract
     * @param _merkleTreeDepth the depth of deposits' Merkle Tree
     */

    constructor(IVerifier _verifier, Poseidon2 _hasher, uint32 _merkleTreeDepth)
        IncrementalMerkleTree(_merkleTreeDepth, _hasher)
    {
        i_verifier = _verifier;
    }

    /**
     * @dev Deposit funds into the contract. The caller must send (for ETH) or approve (for ERC20) value equal to or `denomination` of this instance.
     * @param _commitment the note commitment, which is Poseidon(nullifier + secret)
     */
    function deposit(bytes32 _commitment) external payable nonReentrant {
        // check if the commitment is already added
        if(s_commitments[_commitment]) {
            revert Mixer__CommitmentAlreadyAdded(_commitment);
        }
        // check if the value sent is equal to the denomination
        if (msg.value != DENOMINATION) {
            revert Mixer__DepositValueMismatch({expected: DENOMINATION, actual: msg.value});
        }

        // add the commitment to the added commitments mapping
        s_commitments[_commitment] = true; 

        // insert the commitment into the Merkle tree
        uint32 insertedIndex = _insert(_commitment); 

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    /**
     * @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
     * `input` array consists of:
     *   - merkle root of all deposits in the contract
     *   - hash of unique deposit nullifier to prevent double spends
     *   - the recipient of funds
     *   - optional fee that goes to the transaction sender (usually a relay)
     */
    function withdraw(
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient
    ) external nonReentrant {
        // check if the nullifier is already used
        if (s_nullifierHashes[_nullifierHash]) {
            revert Mixer__NoteAlreadySpent({nullifierHash: _nullifierHash});
        }
        // check if the root is a valid root
        if (!isKnownRoot(_root)) {
            revert Mixer__UnknownRoot({root: _root});
        }
        bytes32[] memory publicInputs = new bytes32[](3);
        publicInputs[0] = _root; // the root of the Merkle tree
        publicInputs[1] = _nullifierHash; // the nullifier hash
        publicInputs[2] = bytes32(uint256(uint160(address(_recipient)))); // the recipient address
        // verify the proof - check the Merkle proof against the root, the ZK proof to check the commitments match, they know a valid nullifier hash and secret, a valid root and the recipient hasn't been modified
        if (!i_verifier.verify(_proof, publicInputs)) {
            revert Mixer__InvalidWithdrawProof();
        }

        s_nullifierHashes[_nullifierHash] = true; // mark the nullifier as used before sending the funds
        (bool success,) = _recipient.call{value: DENOMINATION}("");
        if (!success) {
            revert Mixer__PaymentFailed({recipient: _recipient, amount: DENOMINATION});
        }
        emit Withdrawal(_recipient, _nullifierHash);
    }
}
