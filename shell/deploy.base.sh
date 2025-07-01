#!/bin/bash

# Install Forge dependencies
forge install

# Print the initial deploying message
echo "Deploying Contracts on Base..."

source .env

export ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY_V2
export RPC_URL=$BASE_RPC_URL

read -p "Press enter to begin the deployment..."

forge script script/deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast -vvvv --private-key $PRIVATE_KEY --verify --delay 15
