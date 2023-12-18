import { merkle, ec } from "starknet";
//To run this script -> npx ts-node ./merkletree.ts

// Create an empty array to store the hashes
const addressAmountPairs = [
  {
    address:
      "0x0437Fce03E7fAcd55Df8d3B2774D21eAf3bA1ECd0e7043a6DC4E743D408d8D80",
    amount: BigInt(100),
  },
  {
    address:
      "0x02038e178565b977c99f3e6c8d4ba327356e1b279e84cdc2f1949022c91653bd",
    amount: BigInt(500),
  },
  // Add more pairs as needed
];

// An array to store the hash results as strings
const hashes: string[] = [];

// Iterate through the address-amount pairs and calculate the hashes
for (const pair of addressAmountPairs) {
  const address = pair.address;
  const amount = pair.amount;

  // Calculate the Pedersen hash and push it to the 'hashes' array
  const hashResult = ec.starkCurve.pedersen(address, amount);
  hashes.push(hashResult);
}

// Now 'hashes' contains the Pedersen hashes for each pair
console.log(hashes, " These are the hashes");

// Creating a Merkle tree with these addresses

const merkleTree = new merkle.MerkleTree(hashes);

console.log("Merkle Tree Root --->:", merkleTree.root);
//0x4c5b879125d0fe0e0359dc87eea9c7370756635ca87c59148fb313c2cfb0579 - Produced merkle root for the above

const addressToProve = hashes[1]; // For example, the first address in the list
console.log("Leaf:", addressToProve);
//0x57d0e61d7b5849581495af551721710023a83e705710c58facfa3f4e36e8fac

// Get the Merkle proof for this address
const proof = merkleTree.getProof(addressToProve);
//0x3bf438e95d7428d14eb4270528ff8b1e2f9cb30113724626d5cf9943551ee4d

console.log("Merkle Proof:", proof);

const isPartOfTree = merkle.proofMerklePath(
  merkleTree.root,
  addressToProve,
  proof
);

console.log("Is address part of the tree with the given root?", isPartOfTree);
//yes
