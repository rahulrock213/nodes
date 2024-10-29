channel_logo() {
  echo -e '\033[0;31m'
  echo -e '┌┐ ┌─┐┌─┐┌─┐┌┬┐┬┬ ┬  ┌─┐┬ ┬┌┐ ┬┬  '
  echo -e '├┴┐│ ││ ┬├─┤ │ │└┬┘  └─┐└┬┘├┴┐││  '
  echo -e '└─┘└─┘└─┘┴ ┴ ┴ ┴ ┴   └─┘ ┴ └─┘┴┴─┘'
  echo -e '\e[0m'
  echo -e "\n\nПодпишись на самый 4ekHyTbIu* канал в крипте @bogatiy_sybil [💸]"
}

download_node() {
  sudo apt install lsof

  ports=(8000 9000 9001 9002 9003 8108)

  for port in "${ports[@]}"; do
    if [[ $(lsof -i :"$port" | wc -l) -gt 0 ]]; then
      echo "Ошибка: Порт $port занят. Программа не сможет выполниться."
      exit 1
    fi
  done

  echo -e "Все порты свободны! Сейчас начнется установка...\n"

  read -p "Введите приватный ключ от кошелька, куда будут приходить выплаты (в формате 0x... если у вас в начале нет 0x, то добавьте сами): " PRIVATE_KEY
  read -p "Введите IP адрес вашего сервера (192.133. ...): " SERVER_IP
  read -p "Введите адрес вашего основного кошелька, с помощью которого вы сможете зайти в админ панель: " ADMIN_ADDRESS

  sudo apt update && sudo apt upgrade -y

  sudo apt install curl -y
  sudo apt install ca-certificates
  sudo apt-get install jq
  sudo apt-get install screen

  if ! command -v docker &> /dev/null; then
    sudo apt install docker.io -y
    sudo systemctl start docker
    sudo systemctl enable docker
  fi

  if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  fi
  
  if [ -d "ocean" ]; then
    sudo rm -rf ocean
  fi

  sudo groupadd docker
  sudo usermod -aG docker $USER
  
  mkdir ocean && cd ocean

  HTTP_API_PORT=8000
  P2P_ipV4BindTcpPort=9000
  P2P_ipV4BindWsPort=9001
  P2P_ipV6BindTcpPort=9002
  P2P_ipV6BindWsPort=9003
  P2P_ANNOUNCE_ADDRESSES='["/ip4/'$SERVER_IP'/tcp/'$P2P_ipV4BindTcpPort'", "/ip4/'$SERVER_IP'/ws/tcp/'$P2P_ipV4BindWsPort'"]'

  cat <<EOF > docker-compose.yml
services:
  ocean-node:
    image: oceanprotocol/ocean-node:latest
    pull_policy: always
    container_name: ocean-node
    restart: on-failure
    ports:
      - "$HTTP_API_PORT:$HTTP_API_PORT"
      - "$P2P_ipV4BindTcpPort:$P2P_ipV4BindTcpPort"
      - "$P2P_ipV4BindWsPort:$P2P_ipV4BindWsPort"
      - "$P2P_ipV6BindTcpPort:$P2P_ipV6BindTcpPort"
      - "$P2P_ipV6BindWsPort:$P2P_ipV6BindWsPort"
    environment:
      PRIVATE_KEY: '$PRIVATE_KEY'
      RPCS: '{"1": {"rpc": "https://ethereum-rpc.publicnode.com", "fallbackRPCs": ["https://rpc.ankr.com/eth", "https://1rpc.io/eth", "https://eth.api.onfinality.io/public"], "chainId": 1, "network": "mainnet", "chunkSize": 100}, "10": {"rpc": "https://mainnet.optimism.io", "fallbackRPCs": ["https://optimism-mainnet.public.blastapi.io", "https://rpc.ankr.com/optimism", "https://optimism-rpc.publicnode.com"], "chainId": 10, "network": "optimism", "chunkSize": 100}, "137": {"rpc": "https://polygon-rpc.com/", "fallbackRPCs": ["https://polygon-mainnet.public.blastapi.io", "https://1rpc.io/matic", "https://rpc.ankr.com/polygon"], "chainId": 137, "network": "polygon", "chunkSize": 100}, "23294": {"rpc": "https://sapphire.oasis.io", "fallbackRPCs": ["https://1rpc.io/oasis/sapphire"], "chainId": 23294, "network": "sapphire", "chunkSize": 100}, "23295": {"rpc": "https://testnet.sapphire.oasis.io", "chainId": 23295, "network": "sapphire-testnet", "chunkSize": 100}, "11155111": {"rpc": "https://eth-sepolia.public.blastapi.io", "fallbackRPCs": ["https://1rpc.io/sepolia", "https://eth-sepolia.g.alchemy.com/v2/{API_KEY}"], "chainId": 11155111, "network": "sepolia", "chunkSize": 100}, "11155420": {"rpc": "https://sepolia.optimism.io", "fallbackRPCs": ["https://endpoints.omniatech.io/v1/op/sepolia/public", "https://optimism-sepolia.blockpi.network/v1/rpc/public"], "chainId": 11155420, "network": "optimism-sepolia", "chunkSize": 100}}'
      DB_URL: 'http://typesense:8108/?apiKey=xyz'
      IPFS_GATEWAY: 'https://ipfs.io/'
      ARWEAVE_GATEWAY: 'https://arweave.net/'
      INTERFACES: '["HTTP","P2P"]'
      ALLOWED_ADMINS: '["$ADMIN_ADDRESS"]'
      DASHBOARD: 'true'
      HTTP_API_PORT: '$HTTP_API_PORT'
      P2P_ENABLE_IPV4: 'true'
      P2P_ENABLE_IPV6: 'false'
      P2P_ipV4BindAddress: '0.0.0.0'
      P2P_ipV4BindTcpPort: '$P2P_ipV4BindTcpPort'
      P2P_ipV4BindWsPort: '$P2P_ipV4BindWsPort'
      P2P_ipV6BindAddress: '::'
      P2P_ipV6BindTcpPort: '$P2P_ipV6BindTcpPort'
      P2P_ipV6BindWsPort: '$P2P_ipV6BindWsPort'
      P2P_ANNOUNCE_ADDRESSES: '$P2P_ANNOUNCE_ADDRESSES'
    networks:
      - ocean_network
    depends_on:
      - typesense

  typesense:
    image: typesense/typesense:26.0
    container_name: typesense
    ports:
      - "8108:8108"
    networks:
      - ocean_network
    volumes:
      - typesense-data:/data
    command: '--data-dir /data --api-key=xyz'

volumes:
  typesense-data:
    driver: local

networks:
  ocean_network:
    driver: bridge
EOF

  docker-compose up -d
}

check_logs_ocean() {
  logs_to_check=$(docker ps -a | grep 'oceanprotocol/ocean-node:latest' | awk '{print $1}')
  docker logs $logs_to_check --tail 300 -f
}

check_logs_typesense() {
  logs_to_check=$(docker ps -a | grep 'typesense/typesense' | awk '{print $1}')
  docker logs $logs_to_check --tail 300 -f
}

restart_containers() {
  cd $HOME/ocean/
  docker-compose down
  docker-compose up -d
}

fix_start_problem() {
  cd $HOME/ocean/

  read -p "Введите ваш nodeID (peerID): " value_node

  url="https://incentive-backend.oceanprotocol.com/nodes?page=1&size=10&search=$value_node"

  echo 'Скрипт был запущен...'

  while true; do
    response=$(curl -s "$url")

    if [[ $? -ne 0 ]]; then
      echo "Ошибка при запросе к API: $(curl -s -w '%{http_code}' -o /dev/null "$url")"
      sleep 30
      continue
    fi

    eligible=$(jq -r '.nodes[0]._source.eligible' <<< "$response")

    if [[ $? -ne 0 ]]; then
      echo "Ошибка при обработке JSON: $(jq -r '.nodes[0]._source.eligible' <<< "$response")"
      sleep 30
      continue
    fi

    if [[ "$eligible" == "false" ]]; then
      echo "eligible is false. Выполняем действия..."

      docker-compose down
      docker-compose up -d

      echo "Выполнились..."
    else
      echo "eligible is true. Все хорошо, засыпаем на 2 часа..."
    fi

    sleep 7200  # 2 hours
  done
}

fix_peer() {
  cd $HOME/ocean/

  read -p "Введите ваш API ключ Alchemy: " API_KEY

  NEW_RPC="RPCS: '{\"1\": {\"rpc\": \"https://eth-mainnet.g.alchemy.com/v2/$API_KEY\", \"fallbackRPCs\": [\"https://rpc.ankr.com/eth\", \"https://1rpc.io/eth\"], \"chainId\": 1, \"network\": \"mainnet\", \"chunkSize\": 100}, \"10\": {\"rpc\": \"https://opt-mainnet.g.alchemy.com/v2/$API_KEY\", \"fallbackRPCs\": [\"https://optimism-mainnet.public.blastapi.io\", \"https://rpc.ankr.com/optimism\", \"https://optimism-rpc.publicnode.com\"], \"chainId\": 10, \"network\": \"optimism\", \"chunkSize\": 100}, \"137\": {\"rpc\": \"https://polygon-mainnet.g.alchemy.com/v2/$API_KEY\", \"fallbackRPCs\": [\"https://polygon-mainnet.public.blastapi.io\", \"https://1rpc.io/matic\", \"https://rpc.ankr.com/polygon\"], \"chainId\": 137, \"network\": \"polygon\", \"chunkSize\": 100}, \"23294\": {\"rpc\": \"https://sapphire.oasis.io\", \"fallbackRPCs\": [\"https://1rpc.io/oasis/sapphire\"], \"chainId\": 23294, \"network\": \"sapphire\", \"chunkSize\": 100}, \"11155111\": {\"rpc\": \"https://eth-sepolia.g.alchemy.com/v2/$API_KEY\", \"fallbackRPCs\": [\"https://1rpc.io/sepolia\"], \"chainId\": 11155111, \"network\": \"sepolia\", \"chunkSize\": 100}, \"11155420\": {\"rpc\": \"https://opt-sepolia.g.alchemy.com/v2/$API_KEY\", \"fallbackRPCs\": [\"https://endpoints.omniatech.io/v1/op/sepolia/public\", \"https://optimism-sepolia.blockpi.network/v1/rpc/public\"], \"chainId\": 11155420, \"network\": \"optimism-sepolia\", \"chunkSize\": 100}}'"

  FILE="docker-compose.yml"

  sed -i "s|RPCS:.*|$NEW_RPC|" "$FILE"

  sleep 1

  docker-compose down
  docker-compose up -d

  echo 'Все прошло успешно...'
}

reinstall_node() {
  read -p "Вы уверены? (CTRL+C чтобы выйти): " checkjust

  docker stop $(docker ps -a | grep 'oceanprotocol/ocean-node' | awk '{print $1}')
  docker stop $(docker ps -a | grep 'typesense/typesense' | awk '{print $1}')

  cd $HOME
  sudo rm -r ocean/

  docker rm $(docker ps -a | grep 'oceanprotocol/ocean-node' | awk '{print $1}')
  docker rm $(docker ps -a | grep 'typesense/typesense' | awk '{print $1}')
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🔧 Установить ноду"
    echo "2. 📜 Посмотреть логи OCEAN"
    echo "3. 📜 Посмотреть логи TYPESENSE"
    echo "4. 🔄 Перезагрузить ноду"
    echo "5. 🚀 Запустить скрипт по перезапуску"
    echo "6. 🔐 Изменить на приватный RPC (Alchemy)"
    echo "7. 🗑️ Удалить ноду"
    echo -e "8. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_logs_ocean
        ;;
      3)
        check_logs_typesense
        ;;
      4)
        restart_containers
        ;;
      5)
        fix_start_problem
        ;;
      6)
        fix_peer
        ;;
      7)
        reinstall_node
        ;;
      8)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
