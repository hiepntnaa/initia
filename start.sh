#!/bin/bash

CONFIG_FILE="/root/nubit-node/config/config.json"

NETWORK=$(grep -oP '"network": "\K[^"]+' $CONFIG_FILE)
NODE_TYPE=$(grep -oP '"node_type": "\K[^"]+' $CONFIG_FILE)
PEERS=$(grep -oP '"peers": "\K[^"]+' $CONFIG_FILE)
VALIDATOR_IP=$(grep -oP '"validator_ip": "\K[^"]+' $CONFIG_FILE)
GENESIS_HASH=$(grep -oP '"genesis_hash": "\K[^"]+' $CONFIG_FILE)
AUTH_TYPE=$(grep -oP '"auth_type": "\K[^"]+' $CONFIG_FILE)
START_TIMES=$(grep -oP '"times": \K[^,]+' $CONFIG_FILE)

if [ -z "$NETWORK" ] || [ -z "$NODE_TYPE" ] || [ -z "$PEERS" ] || [ -z "$VALIDATOR_IP" ] || [ -z "$GENESIS_HASH" ] || [ -z "$AUTH_TYPE" ] || [ -z "$START_TIMES" ]; then
  echo "Error reading config file"
  exit 1
fi

export NUBIT_CUSTOM="${NETWORK}:${GENESIS_HASH}:${PEERS}"

BINARY="./bin/nubit"

if [ "$START_TIMES" -eq 0 ]; then
  if [ -d $HOME/.nubit-${NODE_TYPE}-${NETWORK} ]; then
        echo "╔══════════════════════════════════════════════════════════════════════════════════════════════════════"
        echo "║  There is already a ${NODE_TYPE} node nubit-key stored for ${NETWORK}                "
        echo "║                                                                                      "
        echo "║  Rename \"$HOME/.nubit-${NODE_TYPE}-${NETWORK}\" repo and store the past ${NODE_TYPE}"
        echo "║  node repo somewhere you feel safe!                                                  "
        echo "║                                                                                      "
        echo "║  Come back by running ./start.sh                                                     "
        echo "╚══════════════════════════════════════════════════════════════════════════════════════════════════════"
        exit 1
  fi
  $BINARY $NODE_TYPE init  > output.txt
  mnemonic=$(grep -A 1 "MNEMONIC (save this somewhere safe!!!):" output.txt | tail -n 1)
  echo "MNEMONIC (save this somewhere safe!!!):"
  echo $mnemonic > mnemonic.txt
  sleep 1
  cat mnemonic.txt
  rm output.txt

  export AUTH_TYPE
  $BINARY $NODE_TYPE auth $AUTH_TYPE
fi

NEW_START_TIMES=$((START_TIMES + 1))
sed -i.bak "s/\"times\": $START_TIMES/\"times\": $NEW_START_TIMES/" $CONFIG_FILE

$BINARY $NODE_TYPE start --metrics --metrics.tls=false --metrics.endpoint otel.nubit-alphatestnet-1.com:4318 --metrics.interval 3600s
 --p2p.network $NETWORK --core.ip $VALIDATOR_IP --rpc.addr 0.0.0.0
