channel_logo() {
  echo -e '\033[0;31m'
  echo -e '┌┐ ┌─┐┌─┐┌─┐┌┬┐┬┬ ┬  ┌─┐┬ ┬┌┐ ┬┬  '
  echo -e '├┴┐│ ││ ┬├─┤ │ │└┬┘  └─┐└┬┘├┴┐││  '
  echo -e '└─┘└─┘└─┘┴ ┴ ┴ ┴ ┴   └─┘ ┴ └─┘┴┴─┘'
  echo -e '\e[0m'
  echo -e "\n\nПодпишись на самый 4ekHyTbIu* канал в крипте @bogatiy_sybil [💸]"
}

download_node() {
  echo 'Начинаю установку...'

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install make build-essential unzip lz4 gcc git jq -y

  sudo apt install docker.io -y

  sudo systemctl start docker
  sudo systemctl enable docker

  sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  git clone https://github.com/Uniswap/unichain-node
  cd unichain-node || { echo -e "Не получилось зайти в директорию"; return; }

  sed -i '/^[[:space:]]*#.*\.env\.mainnet/s/^[[:space:]]*#/ /' docker-compose.yml

  sudo docker-compose up -d
}

restart_node() {
  HOMEDIR="$HOME"
  sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down
  sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" up -d

  echo 'Unichain был перезагружен'
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
    echo "Один из приватников пустой. Выходим..."
    exit 1
  else
    echo "Продолжаем."
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

  echo 'Нода была обновлена и запущенеа.'
}

display_private_key() {
  cd $HOME
  echo -e 'Ваш приватник GETH: \n' && cat unichain-node/geth-data/geth/nodekey
  echo -e 'Ваш приватник OP-NODE: \n' && cat unichain-node/opnode-data/opnode_p2p_priv.txt
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🚀 Установить ноду"
    echo "2. 🔄 Перезагрузить ноду"
    echo "3. 🕵️ Проверить ноду"
    echo "4. 📋 Посмотреть логи Unichain (OP)"
    echo "5. 📜 Посмотреть логи Unichain"
    echo "6. 🛑 Остановить ноду"
    echo "7. 🆙 Обновить ноду"
    echo "8. 🔑 Посмотреть приватный ключ"
    echo -e "9. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

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
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
