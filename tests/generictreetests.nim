import pkg/merkletree
import pkg/nimcrypto/sha2
import pkg/results
import pkg/questionable/results
import pkg/stew/byteutils
import pkg/chronos
import pkg/asynctest/chronos/unittest2

type
  ByteTreeKey* {.pure.} = enum
    KeyNone = 0x0.byte
    KeyBottomLayer = 0x1.byte
    KeyOdd = 0x2.byte
    KeyOddAndBottomLayer = 0x3.byte

proc testGenericTree*[H, K, U](
    name: string,
    data: openArray[H],
    zero: H,
    compress: proc(z, y: H, key: K): H {.gcsafe, raises: [].},
    makeTree: proc(data: seq[H]): Future[U] {.async.},
) =
  let data = @data

  suite "Correctness tests - " & name:
    test "Should build correct tree for even bottom layer":
      let expectedRoot = compress(
        compress(
          compress(data[0], data[1], K.KeyBottomLayer),
          compress(data[2], data[3], K.KeyBottomLayer),
          K.KeyNone,
        ),
        compress(
          compress(data[4], data[5], K.KeyBottomLayer),
          compress(data[6], data[7], K.KeyBottomLayer),
          K.KeyNone,
        ),
        K.KeyNone,
      )

      let tree = await makeTree(data[0 .. 7])

      check:
        tree.root.tryGet == expectedRoot

    test "Should build correct tree for odd bottom layer":
      let expectedRoot = compress(
        compress(
          compress(data[0], data[1], K.KeyBottomLayer),
          compress(data[2], data[3], K.KeyBottomLayer),
          K.KeyNone,
        ),
        compress(
          compress(data[4], data[5], K.KeyBottomLayer),
          compress(data[6], zero, K.KeyOddAndBottomLayer),
          K.KeyNone,
        ),
        K.KeyNone,
      )

      let tree = await makeTree(data[0 .. 6])

      check:
        tree.root.tryGet == expectedRoot

    test "Should build correct tree for even bottom and odd upper layers":
      let expectedRoot = compress(
        compress(
          compress(
            compress(data[0], data[1], K.KeyBottomLayer),
            compress(data[2], data[3], K.KeyBottomLayer),
            K.KeyNone,
          ),
          compress(
            compress(data[4], data[5], K.KeyBottomLayer),
            compress(data[6], data[7], K.KeyBottomLayer),
            K.KeyNone,
          ),
          K.KeyNone,
        ),
        compress(
          compress(compress(data[8], data[9], K.KeyBottomLayer), zero, K.KeyOdd),
          zero,
          K.KeyOdd,
        ),
        K.KeyNone,
      )

      let tree = await makeTree(data[0 .. 9])

      check:
        tree.root.tryGet == expectedRoot

    test "Should get and validate correct proofs":
      let expectedRoot = compress(
        compress(
          compress(
            compress(data[0], data[1], K.KeyBottomLayer),
            compress(data[2], data[3], K.KeyBottomLayer),
            K.KeyNone,
          ),
          compress(
            compress(data[4], data[5], K.KeyBottomLayer),
            compress(data[6], data[7], K.KeyBottomLayer),
            K.KeyNone,
          ),
          K.KeyNone,
        ),
        compress(
          compress(compress(data[8], data[9], K.KeyBottomLayer), zero, K.KeyOdd),
          zero,
          K.KeyOdd,
        ),
        K.KeyNone,
      )

      let tree = await makeTree(data)

      for i in 0 ..< data.len:
        let proof = tree.getProof(i).tryGet
        check:
          proof.verify(tree.leaves[i], expectedRoot).isOk




