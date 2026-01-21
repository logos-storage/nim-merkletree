# import pkg/unittest2
import pkg/merkletree
import pkg/nimcrypto/sha2
import pkg/results
import pkg/questionable/results
import pkg/stew/byteutils
import pkg/chronos
import pkg/taskpools
import std/cpuinfo
import pkg/asynctest/chronos/unittest2

import ./generictreetests

type
  ByteHash* = seq[byte]
  ByteTree* = MerkleTree[ByteHash, ByteTreeKey]
  ByteProof* = MerkleProof[ByteHash, ByteTreeKey]

const
  data = [
    "00000000000000000000000000000001".toBytes,
    "00000000000000000000000000000002".toBytes,
    "00000000000000000000000000000003".toBytes,
    "00000000000000000000000000000004".toBytes,
    "00000000000000000000000000000005".toBytes,
    "00000000000000000000000000000006".toBytes,
    "00000000000000000000000000000007".toBytes,
    "00000000000000000000000000000008".toBytes,
    "00000000000000000000000000000009".toBytes,
    "00000000000000000000000000000010".toBytes,
  ]
  digestSize = sha256.sizeDigest
  zero: seq[byte] = newSeq[byte](digestSize)
  compress = func(x, y: seq[byte], key: ByteTreeKey): seq[byte] {.gcsafe, raises: [].}  =
    let input = x & y & @[key.byte]
    let digest = sha256.digest(input)
    @(digest.data)

  makeTree = proc(data: seq[seq[byte]]): Future[ByteTree] {.async.} =
    var tree = ByteTree()
    let compress = func(x, y: seq[byte], key: ByteTreeKey): ?!seq[byte] =
      # Use Result form of `compress` to match expected type of prepare
      success compress(x, y, key)

    tree.prepare(compress, zero, data).expect("should prepare merkletree")
    
    let tp = Taskpool.new(numThreads = min(countProcessors(), 16))
    (await tree.compute(tp)).expect("should compute merkletree")
    return tree

testGenericTree("ByteTree Multithreaded", @data, zero, compress, makeTree)
