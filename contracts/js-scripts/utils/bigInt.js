import {randomBytes} from "crypto";
// Generates a random BigInt of specified byte length
export const rbigint = (nbytes) => leBufferToBigint(randomBytes(nbytes));

// Converts a hex string value to Bigint.
export function hexToBigint(value) {
  if (typeof value === "string") {
    // If it's a hex string
    if (value.startsWith("0x")) {
      return BigInt(value);
    }
    return BigInt("0x" + value);
  }
  // If it's already a number or BigInt
  return BigInt(value);
}

// Converts a Bigint to hex string of specified length
export const bigintToHex = (number, length = 32) =>
  "0x" + number.toString(16).padStart(length * 2, "0");

// Converts a buffer of bytes into a BigInt, assuming little-endian byte order.


// Converts a BigInt to a little-endian Buffer of specified byte length.
export function leBigintToBuffer(num, byteLength) {
  if (num < 0n) throw new Error("BigInt must be non-negative");

  // Validate that byteLength is sufficient to represent the number
  const requiredLength = Math.ceil(num.toString(2).length / 8);
  if (byteLength < requiredLength) {
    throw new Error(
      `The specified byteLength (${byteLength}) is too small to represent the number`
    );
  }

  const buffer = Buffer.alloc(byteLength);

  // Fill the buffer with bytes from BigInt in little-endian order
  for (let i = 0; i < byteLength; i++) {
    buffer[i] = Number(num & 0xffn); // Get the lowest 8 bits
    num >>= 8n; // Shift by 8 bits to the right
  }

  return buffer;
}
