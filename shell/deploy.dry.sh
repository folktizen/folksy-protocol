#!/bin/bash

# Install Forge dependencies
forge install

# Print the initial deploying message
echo "Dry Deploy Contracts on Base..."

source .env

export ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY_V2
export RPC_URL=$BASE_RPC_URL

read -p "Press enter to begin the dry run deployment..."

forge script script/deploy.s.sol:Deploy --rpc-url $RPC_URL --ffi --slow --private-key $PRIVATE_KEY -- --dry-run
