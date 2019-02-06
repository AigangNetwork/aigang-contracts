#!/usr/bin/env bash

#pip3 install solidity-flattener --no-cache-dir -U

solidity_flattener contracts/pools/PrizeCalculator.sol --out build/flat/PrizeCalculator_flat.sol --solc-paths="..=contracts"
solidity_flattener contracts/pools/Pools.sol --out build/flat/Pools_flat.sol --solc-paths="..=contracts"
solidity_flattener contracts/AddressManager.sol --out build/flat/AddressManager_flat.sol --solc-paths="..=contracts"

