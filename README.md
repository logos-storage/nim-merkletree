# nim-merkletree

A flexible and efficient Merkle tree implementation in Nim for cryptographic proof generation and verification.

## Overview

`nim-merkletree` provides a generic Merkle tree data structure that enables efficient cryptographic proof generation for data integrity verification. This library is designed for use in distributed systems, blockchain applications, and decentralized storage networks where proving data membership and integrity is critical.

The library is primarily used in [Logos Storage](https://github.com/logos-storage/logos-storage-nim) (formerly Codex), a privacy-preserving decentralized storage system, where it powers the `StorageMerkleTree` implementation for verifying storage proofs and data integrity.

## Installation

Add `nim-merkletree` to your project's `.nimble` file:

```nim
requires "merkletree"
```

Or install directly via Nimble:

```bash
nimble install https://github.com/logos-storage/nim-merkletree
```

## Example usage - create a `ByteTree`

```nim
import std/cpuinfo
import pkg/chronos
import pkg/merkletree
import pkg/nimcrypto/sha2
import pkg/questionable/results
import pkg/stew/byteutils
import pkg/taskpools

type
  ByteTreeKey* {.pure.} = enum
    KeyNone = 0x0.byte
    KeyBottomLayer = 0x1.byte
    KeyOdd = 0x2.byte
    KeyOddAndBottomLayer = 0x3.byte
  ByteHash* = seq[byte]
  ByteTree* = MerkleTree[ByteHash, ByteTreeKey]
  ByteProof* = MerkleProof[ByteHash, ByteTreeKey]

# Create a Merkle tree from your data
const
  data = [
    "00000000000000000000000000000001".toBytes,
    "00000000000000000000000000000002".toBytes,
    "00000000000000000000000000000003".toBytes,
  ]
  digestSize = sha256.sizeDigest
  zero: seq[byte] = newSeq[byte](digestSize)

proc computeAndVerify(): Future[bool] {.async.} =
  
  var tree = ByteTree()

  # Define the hashing function
  let compress = func(x, y: seq[byte], key: ByteTreeKey): ?!seq[byte] =
    let input = x & y & @[key.byte]
    let digest = sha256.digest(input)
    success @(digest.data)

  # Prepare the tree
  tree.prepare(compress, zero, data).expect("should prepare merkletree")

  # Compute the tree using multiple threads
  let tp = Taskpool.new(numThreads = min(countProcessors(), 16))

  (await tree.compute(tp)).expect("should compute merkletree")

  # Get the Merkle root
  let root = tree.root().expect("should get root")

  # Generate a proof for a specific element
  let proof = tree.getProof(0).expect("should get proof") # Proof for "00000000000000000000000000000001".toBytes

  # Verify the proof
  let isValid = proof.verify(ByteHash(data[0]), root).expect("should verify proof")

  return isValid

assert waitFor computeAndVerify()
```

## Testing

Run the test suite:

```bash
nimble test
```

## License

[![License: Apache](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Status

This library is currently in active development and not yet in production. The API may change as we optimize for performance and usability based on real-world usage patterns.

## Support

- **Issues**: [GitHub Issues](https://github.com/logos-storage/nim-merkletree/issues)
- **Discord**: Join the [Logos Discord](https://discord.gg/logos) for community support
