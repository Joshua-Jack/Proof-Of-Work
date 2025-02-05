#!/bin/bash

# Load environment variables
source .env

# Deploy to Lisk Sepolia
forge script script/Vault.s.sol:VaultScript \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify \
    --verifier blockscout \
    --verifier-url https://sepolia-blockscout.lisk.com/api \
    -vvvv