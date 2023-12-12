#!/bin/bash

# Deployment script for `UnruggableMemecoin` contract
# Arguments:
# 1: recipient address that will receive the initial supply of tokens
# 2: name of the token
# 3: symbol of the token
# 4: initial supply of tokens
RECIPIENT_ADDRESS=$1
TOKEN_NAME=$2
TOKEN_SYMBOL=$3
INITIAL_SUPPLY=$4
DECIMALS_18_SUFFIX="000000000000000000"

# Requires the following env variables to be set:
# - STARKNET_KEYSTORE: path to the keystore file
# - STARKNET_ACCOUNT: path to the account file
# - STARKNET_RPC: RPC URL of the Starknet network to deploy to

###############################################
# DECLARE THE CONTRACT CLASS                  #
###############################################

# Prepare declare args
COMPILER_VERSION="2.1.0"
CONTRACT_CLASS_FILE="./target/dev/unruggablememecoin_UnruggableMemecoin.contract_class.json"
DECLARE_ARGS="--compiler-version=$COMPILER_VERSION"

# Declare the contract and capture the command output
command_output=$(starkli declare $CONTRACT_CLASS_FILE $DECLARE_ARGS --watch)

from_string="Class hash declared:"
class_hash="${command_output#*$from_string}"

echo "Class hash: $class_hash"

###############################################
# DEPLOY THE CONTRACT                         #
###############################################

# Deploy the contract using the extracted class hash
starkli deploy $class_hash $RECIPIENT_ADDRESS str:$TOKEN_NAME str:$TOKEN_SYMBOL u256:$INITIAL_SUPPLY$DECIMALS_18_SUFFIX