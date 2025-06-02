// Import ethers
const { ethers } = require("ethers");
require("dotenv").config();

// Set up provider (e.g., Infura, Alchemy, or local node)
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);

const contractAddress = "0xYourContractAddressHere";
const contractABI = ["event Withdraw(address indexed from, uint256 amount)"];

// Connect to contract
const contract = new ethers.Contract(contractAddress, contractABI, provider);

// Create the filter
const filter = contract.filters.Withdraw();

async function getWithdrawEvents() {
  const events = await contract.queryFilter(filter, 0, "latest");
  for (const e of events) {
    console.log(
      `From: ${e.args.from}, Amount: ${ethers.formatEther(e.args.amount)} ETH`
    );
  }
}

async function withdraw() {
    // get the withdrawals
    getWithdrawEvents();
}
