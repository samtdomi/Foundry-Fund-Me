// SPDX-License-Identifier: MIT

// 1. Deploy Mocks when we are on a local Anvil chain
// 2. Keep track of contract addresses across different chains
// Sepolia ETH/USD address
// Mainnet ETH/USD address
// Goerli ETH/USD address

pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // if on a local Anvil chain, deploy mocks
    // otherwise, grab the existing address from the specific network being used

    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // ETH/USD price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });

        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // ETH/USD price feed address
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });

        return mainnetConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // ETH/USD price feed address

        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // 1. Deploy Mocks
        // 2. return Mock addresses
        uint8 Decimals = 8; // How may decimals are used in the eth/usd price answer
        int256 InitialPrice = 2000e8; // initial price is 2,000 and adds 8 0's to satisfy the 8 decimals

        vm.startBroadcast(); // start broadcast when deploying a contract
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            Decimals,
            InitialPrice
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });

        return anvilConfig;
    }
}
