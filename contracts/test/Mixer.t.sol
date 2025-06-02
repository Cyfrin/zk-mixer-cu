// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {HonkVerifier} from "../src/Verifier.sol";
import {Mixer, IVerifier, Poseidon2} from "../src/Mixer.sol";
import {IncrementalMerkleTree} from "../src/IncrementalMerkleTree.sol";

contract ETHTornadoTest is Test {
    uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    IVerifier public verifier;
    Mixer public mixer;
    Poseidon2 public poseidon;

    // Test vars
    address public recipient = makeAddr("recipient");

    // why do i need this?
    // function deployMimcSponge(bytes memory bytecode) public returns (address) {
    //     address deployedAddress;
    //     assembly {
    //         deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
    //         if iszero(deployedAddress) { revert(0, 0) }
    //     }
    //     return deployedAddress;
    // }

    function setUp() public {
        // Deploy Poseiden hasher contract
        poseidon = new Poseidon2();

        // Deploy Groth16 verifier contract.
        verifier = new HonkVerifier();

        /**
         * Deploy Tornado Cash mixer
         *
         * - verifier: HonkVerifier contract
         * - hasher: Poseidon2 contract
         * - denomination: 0.001 ETH
         * - merkleTreeHeight: 20
         */
        mixer = new Mixer(IVerifier(verifier), poseidon, 20);
    }

    function _getProof(
        bytes32 _nullifier,
        bytes32 _secret,
        address _recipient,
        bytes32[] memory leaves
    ) internal returns (bytes memory proof, bytes32[] memory publicInputs) {
        string[] memory inputs = new string[](6 + leaves.length);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateProof.ts"; // change folder name?
        inputs[3] = vm.toString(_nullifier);
        inputs[4] = vm.toString(_secret);
        inputs[5] = vm.toString(bytes32(uint256(uint160(_recipient))));

        for (uint256 i = 0; i < leaves.length; i++) {
            inputs[6 + i] = vm.toString(leaves[i]);
        }

        bytes memory result = vm.ffi(inputs);
        (proof, publicInputs) =
            abi.decode(result, (bytes, bytes32[]));
    }

    function _getCommitment() internal returns (bytes32 commitment, bytes32 nullifier, bytes32 secret) {
        string[] memory inputs = new string[](3);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateCommitment.ts";

        bytes memory result = vm.ffi(inputs);
        (commitment, nullifier, secret) = abi.decode(result, (bytes32, bytes32, bytes32));

        return (commitment, nullifier, secret);
    }

    function testGetCommitment() public {
        (bytes32 commitment, bytes32 nullifier, bytes32 secret) = _getCommitment();
        console.log("Commitment: ");
        console.logBytes32(commitment);
        console.log("Nullifier: ");
        console.logBytes32(nullifier);
        console.log("Secret: ");
        console.logBytes32(secret);
        console.log("Recipient: ");
        console.log(recipient);
        assertTrue(commitment != 0);
        assertTrue(nullifier != 0);
        assertTrue(secret != 0);
    }

    function testGetProof() public {
        (bytes32 commitment, bytes32 nullifier, bytes32 secret) = _getCommitment();
        console.log("Commitment: ");
        console.logBytes32(commitment);
        console.log("Nullifier: ");
        console.logBytes32(nullifier);
        console.log("Secret: ");
        console.logBytes32(secret);
        
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = commitment;

        (bytes memory proof, bytes32[] memory publicInputs) =
            _getProof(nullifier, secret, recipient, leaves);
    }

    function testMixerSingleDeposit() public {
        // 1. Generate commitment and deposit
        (bytes32 commitment, bytes32 nullifier, bytes32 secret) = _getCommitment();

        // NOTE: make this a fixed denomination
        mixer.deposit{value: mixer.DENOMINATION()}(commitment);

        // 2. Generate witness and proof.
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = commitment;
        (bytes memory proof, bytes32[] memory publicInputs) =
            _getProof(nullifier, secret, recipient, leaves);
        // root
        console.log("PublicInputs[0]: ");
        console.logBytes32(publicInputs[0]);
        // nullifierHash
        console.log("PublicInputs[1]: ");
        console.logBytes32(publicInputs[1]);
        // recipient
        console.log("PublicInputs[2]: ");
        console.logBytes32(publicInputs[2]);
        
        // 3. Verify proof against the verifier contract.
        // bytes32[] memory publicInputs = new bytes32[](3);
        // publicInputs[0] = root; // the root of the Merkle tree
        // publicInputs[1] = nullifierHash; // the nullifier hash
        // publicInputs[2] = bytes32(uint256(uint160(recipient))); // the recipient address
        assertTrue(
            verifier.verify(
                proof,
                publicInputs
            )
        );

        // 4. Withdraw funds from the contract.
        assertEq(recipient.balance, 0);
        assertEq(address(mixer).balance, mixer.DENOMINATION());
        console.log("last root: ");
        console.logBytes32(mixer.getLastRoot());
        mixer.withdraw(proof, publicInputs[0], publicInputs[1], payable(recipient));
        assertEq(recipient.balance, mixer.DENOMINATION());
        assertEq(address(mixer).balance, 0);
    }
}