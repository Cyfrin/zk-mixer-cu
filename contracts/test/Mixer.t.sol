// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {HonkVerifier} from "../src/Verifier.sol";
import {Mixer, IVerifier, Poseidon2} from "../src/Mixer.sol";
import {IncrementalMerkleTree} from "../src/IncrementalMerkleTree.sol";

contract ETHTornadoTest is Test {
    IVerifier public verifier;
    Mixer public mixer;
    Poseidon2 public poseidon;

    address public recipient = makeAddr("recipient");

    function setUp() public {
        // Deploy Poseiden hasher contract
        poseidon = new Poseidon2();

        // Deploy Groth16 verifier contract.
        verifier = new HonkVerifier();


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

    function testMakeDeposit() public {
        // create a commitment
        // make a deposit
        (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) = _getCommitment();
        console.log("Commitment: ");
        console.logBytes32(_commitment);
        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);
    }

    function testMakeWithdrawal() public {
        // make a deposit
        (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) = _getCommitment();
        console.log("Commitment: ");
        console.logBytes32(_commitment);
        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);

        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _commitment;
        // create a proof
        (bytes memory _proof, bytes32[] memory _publicInputs) = _getProof(_nullifier, _secret, recipient, leaves);
        assertTrue(verifier.verify(_proof, _publicInputs));
        // make a withdrawal
        assertEq(recipient.balance, 0);
        assertEq(address(mixer).balance, mixer.DENOMINATION());
        mixer.withdraw(_proof, _publicInputs[0], _publicInputs[1], payable(address(uint160(uint256(_publicInputs[2])))));
        assertEq(recipient.balance, mixer.DENOMINATION());
        assertEq(address(mixer).balance, 0);
    }

    function testAnotherAddressSendProof() public {
        // make a deposit
        (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) = _getCommitment();
        console.log("Commitment: ");
        console.logBytes32(_commitment);
        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);

        // create a proof
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _commitment;
        (bytes memory _proof, bytes32[] memory _publicInputs) = _getProof(_nullifier, _secret, recipient, leaves);

        // make a withdrawal
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert();
        mixer.withdraw(_proof, _publicInputs[0], _publicInputs[1], payable(attacker));
    }
}