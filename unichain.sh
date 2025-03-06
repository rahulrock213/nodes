channel_logo() {
  echo -e '\033[0;31m'
  echo -e 'â”Œâ” â”Œâ”€â”â”Œâ”€â”â”Œâ”€â”â”Œâ”¬â”â”¬â”¬ â”¬  â”Œâ”€â”â”¬ â”¬â”Œâ” â”¬â”¬  '
  echo -e 'â”œâ”´â”â”‚ â”‚â”‚ â”¬â”œâ”€â”¤ â”‚ â”‚â””â”¬â”˜  â””â”€â”â””â”¬â”˜â”œâ”´â”â”‚â”‚  '
  echo -e 'â””â”€â”˜â””â”€â”˜â””â”€â”˜â”´ â”´ â”´ â”´ â”´   â””â”€â”˜ â”´ â””â”€â”˜â”´â”´â”€â”˜'
  echo -e '\e[0m'
  echo -e "\n\nSubscribe to the most 4ekHyTbIu* crypto channel @bogatiy_sybil [ðŸ’¸]"
}

download_node() {
  echo 'Starting installation...'

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install make build-essential unzip lz4 gcc git jq -y

  sudo apt install docker.io -y

  sudo systemctl start docker
  sudo systemctl enable docker

  sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  git clone https://github.com/Uniswap/unichain-node
  cd unichain-node || { echo -e "Failed to enter directory"; return; }

  sed -i '/^[[:space:]]*#.*\.env\.mainnet/s/^[[:space:]]*#/ /' docker-compose.yml

  sudo docker-compose up -d
}

restart_node() {
  HOMEDIR="$HOME"
  sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down
  sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" up -d

  echo 'Unichain has been restarted'
}

check_node() {
  response=$(curl -s -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
    -H "Content-Type: application/json" http://localhost:8545)

  echo -e "${BLUE}RESPONSE:${RESET} $response"
}

check_logs_op_node() {
  sudo docker logs unichain-node-op-node-1 --tail 300
}

check_logs_unichain() {
  sudo docker logs unichain-node-execution-client-1 --tail 300
}

stop_node() {
  HOMEDIR="$HOME"
  sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down
}

update_node() {
  cd $HOME

  HOMEDIR="$HOME"
  sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down

  op_node_container=$(docker ps --filter "name=op-node" --format "{{.ID}}")
  op_geth_container=$(docker ps --filter "name=op-geth" --format "{{.ID}}")

  docker stop "$op_node_container"
  docker stop "$op_geth_container"

  docker rm "$op_node_container"
  docker rm "$op_geth_container"

  P2P_PRIV_KEY=$(cat $HOME/unichain-node/opnode-data/opnode_p2p_priv.txt)
  GETH_PRIV_KEY=$(cat $HOME/unichain-node/geth-data/geth/nodekey)

  if [ -z "$P2P_PRIV_KEY" ] || [ -z "$GETH_PRIV_KEY" ]; then
    echo "One of the private keys is empty. Exiting..."
    exit 1
  else
    echo "Continuing."
  fi

  sudo rm -rf unichain-node/
  git clone https://github.com/Uniswap/unichain-node

  cd unichain-node

  sed -i '/^[[:space:]]*#.*\.env\.mainnet/s/^[[:space:]]*#/ /' docker-compose.yml

  mkdir opnode-data
  cd opnode-data
  echo $P2P_PRIV_KEY > opnode_p2p_priv.txt

  cd $HOME/unichain-node
  mkdir geth-data
  cd geth-data
  mkdir geth
  cd geth
  echo $GETH_PRIV_KEY > nodekey

  cd $HOME/unichain-node

  sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" up -d

  echo 'The node has been updated and started.'
}

display_private_key() {
  cd $HOME
  echo -e 'Your GETH private key: \n' && cat unichain-node/geth-data/geth/nodekey
  echo -e 'Your OP-NODE private key: \n' && cat unichain-node/opnode-data/opnode_p2p_priv.txt
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nMenu:"
    echo "1. ðŸš€ Install node"
    echo "2. ðŸ”„ Restart node"
    echo "3. ðŸ•µï¸ Check node"
    echo "4. ðŸ“‹ View Unichain logs (OP)"
    echo "5. ðŸ“œ View Unichain logs"
    echo "6. ðŸ›‘ Stop node"
    echo "7. ðŸ†™ Update node"
    echo "8. ðŸ”‘ View private key"
    echo -e "9. ðŸšª Exit script\n"
    read -p "Select a menu option: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        restart_node
        ;;
      3)
        check_node
        ;;
      4)
        check_logs_op_node
        ;;
      5)
        check_logs_unichain
        ;;
      6)
        stop_node
        ;;
      7)
        update_node
        ;;
      8)
        display_private_key
        ;;
      9)
        exit_from_script
        ;;
      *)
        echo "Invalid option. Please select a valid number from the menu."
        ;;
    esac
  done
