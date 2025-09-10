require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

/**
 * @title Hardhat Configuration for Warp-Speed DeFi Protocol
 * @dev Consciousness-aware blockchain deployment configuration
 * @notice Supports multiple networks with quantum-enhanced parameters
 */

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          yul: true,
          yulDetails: {
            stackAllocation: true,
            optimizerSteps: "dhfoDgvulfnTUtnIf"
          }
        }
      },
      viaIR: true,
      metadata: {
        bytecodeHash: "none"
      }
    }
  },

  networks: {
    // Local development network
    hardhat: {
      chainId: 31337,
      gasPrice: "auto",
      gasMultiplier: 1.2,
      blockGasLimit: 30000000,
      accounts: {
        count: 10,
        accountsBalance: "10000000000000000000000" // 10,000 ETH per account
      },
      mining: {
        auto: true,
        interval: 3000 // 3 second block time
      },
      forking: process.env.MAINNET_FORK_URL ? {
        url: process.env.MAINNET_FORK_URL,
        blockNumber: process.env.FORK_BLOCK_NUMBER ? parseInt(process.env.FORK_BLOCK_NUMBER) : undefined
      } : undefined
    },

    // Localhost network
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
      gasPrice: "auto",
      timeout: 60000
    },

    // Ethereum Mainnet - Production deployment
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "https://mainnet.infura.io/v3/YOUR_INFURA_KEY",
      accounts: process.env.MAINNET_PRIVATE_KEY ? [process.env.MAINNET_PRIVATE_KEY] : [],
      chainId: 1,
      gasPrice: "auto",
      gasMultiplier: 1.1,
      timeout: 120000,
      confirmations: 2
    },

    // Ethereum Goerli Testnet
    goerli: {
      url: process.env.GOERLI_RPC_URL || "https://goerli.infura.io/v3/YOUR_INFURA_KEY",
      accounts: process.env.TESTNET_PRIVATE_KEY ? [process.env.TESTNET_PRIVATE_KEY] : [],
      chainId: 5,
      gasPrice: "auto",
      gasMultiplier: 1.2,
      timeout: 60000
    },

    // Ethereum Sepolia Testnet
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "https://sepolia.infura.io/v3/YOUR_INFURA_KEY",
      accounts: process.env.TESTNET_PRIVATE_KEY ? [process.env.TESTNET_PRIVATE_KEY] : [],
      chainId: 11155111,
      gasPrice: "auto",
      gasMultiplier: 1.2,
      timeout: 60000
    },

    // Polygon Mainnet
    polygon: {
      url: process.env.POLYGON_RPC_URL || "https://polygon-mainnet.infura.io/v3/YOUR_INFURA_KEY",
      accounts: process.env.POLYGON_PRIVATE_KEY ? [process.env.POLYGON_PRIVATE_KEY] : [],
      chainId: 137,
      gasPrice: "auto",
      gasMultiplier: 1.2,
      timeout: 60000
    },

    // Polygon Mumbai Testnet
    mumbai: {
      url: process.env.MUMBAI_RPC_URL || "https://polygon-mumbai.infura.io/v3/YOUR_INFURA_KEY",
      accounts: process.env.TESTNET_PRIVATE_KEY ? [process.env.TESTNET_PRIVATE_KEY] : [],
      chainId: 80001,
      gasPrice: "auto",
      gasMultiplier: 1.5,
      timeout: 60000
    },

    // Arbitrum Mainnet
    arbitrum: {
      url: process.env.ARBITRUM_RPC_URL || "https://arbitrum-mainnet.infura.io/v3/YOUR_INFURA_KEY",
      accounts: process.env.ARBITRUM_PRIVATE_KEY ? [process.env.ARBITRUM_PRIVATE_KEY] : [],
      chainId: 42161,
      gasPrice: "auto",
      timeout: 60000
    },

    // Optimism Mainnet
    optimism: {
      url: process.env.OPTIMISM_RPC_URL || "https://optimism-mainnet.infura.io/v3/YOUR_INFURA_KEY",
      accounts: process.env.OPTIMISM_PRIVATE_KEY ? [process.env.OPTIMISM_PRIVATE_KEY] : [],
      chainId: 10,
      gasPrice: "auto",
      timeout: 60000
    },

    // BSC Mainnet
    bsc: {
      url: process.env.BSC_RPC_URL || "https://bsc-dataseed.binance.org/",
      accounts: process.env.BSC_PRIVATE_KEY ? [process.env.BSC_PRIVATE_KEY] : [],
      chainId: 56,
      gasPrice: "auto",
      gasMultiplier: 1.2,
      timeout: 60000
    },

    // Avalanche Mainnet
    avalanche: {
      url: process.env.AVALANCHE_RPC_URL || "https://api.avax.network/ext/bc/C/rpc",
      accounts: process.env.AVALANCHE_PRIVATE_KEY ? [process.env.AVALANCHE_PRIVATE_KEY] : [],
      chainId: 43114,
      gasPrice: "auto",
      timeout: 60000
    }
  },

  // Contract verification settings
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      goerli: process.env.ETHERSCAN_API_KEY || "",
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      polygon: process.env.POLYGONSCAN_API_KEY || "",
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || "",
      arbitrumOne: process.env.ARBISCAN_API_KEY || "",
      optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_API_KEY || "",
      bsc: process.env.BSCSCAN_API_KEY || "",
      avalanche: process.env.SNOWTRACE_API_KEY || ""
    },
    customChains: [
      {
        network: "arbitrumGoerli",
        chainId: 421613,
        urls: {
          apiURL: "https://api-goerli.arbiscan.io/api",
          browserURL: "https://goerli.arbiscan.io"
        }
      }
    ]
  },

  // Gas reporting
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
    gasPrice: 20,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY || "",
    showTimeSpent: true,
    showMethodSig: true,
    maxMethodDiff: 10,
    rst: true,
    rstTitle: "Warp-Speed DeFi Protocol Gas Report",
    outputFile: "./gas-report.txt",
    noColors: false
  },

  // Contract size limits
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    only: ["ValueAnchor", "DeFiYieldFarm"]
  },

  // Test configuration
  mocha: {
    timeout: 120000,
    reporter: "spec",
    slow: 5000,
    bail: false,
    recursive: true
  },

  // Path configuration
  paths: {
    sources: "./src/blockchain",
    tests: "./test/blockchain",
    cache: "./cache",
    artifacts: "./artifacts"
  },

  // Console logging
  console: {
    level: "info"
  },

  // Warnings configuration
  warnings: {
    "*": {
      "unreachable-code": false,
      "unused-param": false
    }
  }
};