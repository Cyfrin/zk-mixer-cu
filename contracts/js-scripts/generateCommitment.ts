import { Barretenberg, Fr } from "@aztec/bb.js";
import { ethers } from "ethers";

// // Convert a bigint to a hex string of fixed length
// const bigintToHex = (number: bigint, length: number = 32): string =>
//   "0x" + number.toString(16).padStart(length * 2, "0");

// // Convert a little-endian buffer to a bigint
// const leBufferToBigint = (buff: Buffer): bigint => {
//   let res = 0n;
//   for (let i = 0; i < buff.length; i++) {
//     res = (res << 8n) + BigInt(buff[i]);
//   }
//   return res;
// };


// generateCommitment
export default async function generateCommitment(): Promise<string> {
  // Initialize Barretenberg
  const bb = await Barretenberg.new();

  // 1. generate nullifier
  const nullifier = Fr.random();

  // 2. generate secret
  const secret = Fr.random();

  // 3. create commitment
  const commitment: Fr = await bb.poseidon2Hash([nullifier, secret]);

  const res = ethers.AbiCoder.defaultAbiCoder().encode(
    ["bytes32", "bytes32", "bytes32"],
    [commitment.toBuffer(), nullifier.toBuffer(), secret.toBuffer()]
  );

  // console.log("Commitment: ", commitment.toString());
  // console.log("Nullifier: ", nullifier.toString());
  // console.log("Secret: ", secret.toString());

  return res;
}

(async () => {
  generateCommitment()
  .then((res) => {
    process.stdout.write(res);
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  // const [commitment, nullifier, secret] = ethers.AbiCoder.defaultAbiCoder().decode(
  //   ["bytes32", "bytes32", "bytes32"],
  //   res
  // );
})();
