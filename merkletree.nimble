# Package

version       = "0.1.0"
author        = "Logos Storage team"
description   = "Merkle tree implementation used for Logos Storage"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 2.2.6"
requires "questionable ~= 0.10.15"
requires "stew ~= 0.4.2"
requires "taskpools ~= 0.1.0"
requires "chronos ~= 4.0.4"
requires "asynctest ~= 0.5.4"

dev:
  requires "nimcrypto ~= 0.7.3"
