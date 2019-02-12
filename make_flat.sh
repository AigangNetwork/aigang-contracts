#!/usr/bin/env bash

#pip3 install solidity-flattener --no-cache-dir -U

# common
solidity_flattener contracts/AddressManager.sol --out build/flat/AddressManager_flat.sol --solc-paths="..=contracts"

# pools
solidity_flattener contracts/pools/PrizeCalculator.sol --out build/flat/PrizeCalculator_flat.sol --solc-paths="..=contracts"
solidity_flattener contracts/pools/Pools.sol --out build/flat/Pools_flat.sol --solc-paths="..=contracts"

# prediction market
solidity_flattener contracts/predictions/PrizeCalculator.sol --out build/flat/PrizeCalculator_Insurance_flat.sol --solc-paths="..=contracts"
solidity_flattener contracts/predictions/Market.sol --out build/flat/Market_flat.sol --solc-paths="..=contracts"

# insurance
solidity_flattener contracts/insurance/PremiumCalculator.sol --out build/flat/PremiumCalculator_flat.sol --solc-paths="..=contracts"
solidity_flattener contracts/insurance/Product.sol --out build/flat/Product_flat.sol --solc-paths="..=contracts"

