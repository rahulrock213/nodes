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

  echo -e "Все порты свободны!\n"

  read -p "Введите приватный ключ от кошелька, куда будут приходить выплаты (в формате 0x... если у вас в начале нет 0x, то добавьте сами): " PRIVATE_KEY
  read -p "Введите IP адрес вашего сервера (192.133. ...): " SERVER_IP
  read -p "Введите адрес вашего основного кошелька, с помощью которого вы сможете зайти в админ панель: " ADMIN_ADDRESS

  sudo apt update & sudo apt upgrade -y

  if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
    echo "Docker успешно установлен."
  else
    echo "Docker is already installed. Skip the installation."
  fi

  # Installing the necessary packages
  sudo apt install screen curl git wget nano -y

  # Install NodeJS & NPM (version 20.16.1 minimum)
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs

  # Typesense installation (API KEY is 'xyz' by default, you can change it)
  export TYPESENSE_API_KEY=xyz
    
  sudo mkdir "$(pwd)"/typesense-data

  sudo docker run -d -p 8108:8108 \
            -v "$(pwd)"/typesense-data:/data typesense/typesense:26.0 \
            --data-dir /data \
            --api-key=$TYPESENSE_API_KEY \
            --enable-cors

  # Check if the ocean-node folder already exists
  if [ ! -d "ocean-node" ]; then
    sudo git clone https://github.com/oceanprotocol/ocean-node.git
  fi

  cd ocean-node

  # Checking for a Dockerfile
  if [ ! -f "Dockerfile" ]; then
    echo "Error: Dockerfile not found in ocean-node folder."
    exit 1
  fi

  # Check if the image is available and build it if necessary
  if [[ "$(sudo docker images -q ocean-node:mybuild 2> /dev/null)" == "" ]]; then
    echo "Docker image build..."
    sudo docker build -t ocean-node:mybuild .
    if [[ $? -ne 0 ]]; then
        echo "Error: Image build failed."
        exit 1
    fi
  else
    echo "The ocean-node:mybuild image already exists."
  fi

  cat <<EOF > .env
# Environmental Variables

#check env.md file for examples and descriptions on each variable

#----------------- REQUIRED --------------------------
#This is the only required/mandatory variable
#Node will simply not run without this variable
#All the other variables can remain blank (because they have defaults) or simply commented
PRIVATE_KEY=$PRIVATE_KEY
#-----------------------------------------------------

## core
INDEXER_NETWORKS=["23295", "11155420"]
RPCS={"23295":{"rpc":"https://testnet.sapphire.oasis.io","chainId":23295,"network":"oasis_saphire_testnet","chunkSize":100},"11155420":{"rpc":"https://sepolia.optimism.io","chainId":11155420,"network":"optimism-sepolia","chunkSize":100}}
DB_URL=http://$SERVER_IP:8108/?apiKey=xyz
IPFS_GATEWAY=https://ipfs.io/
ARWEAVE_GATEWAY=https://arweave.net/
LOAD_INITIAL_DDOS=
FEE_TOKENS=
FEE_AMOUNT=
ADDRESS_FILE=
NODE_ENV=
AUTHORIZED_DECRYPTERS=
OPERATOR_SERVICE_URL=
INTERFACES=["HTTP","P2P"]
ALLOWED_VALIDATORS=
INDEXER_INTERVAL=
ALLOWED_ADMINS=["$ADMIN_ADDRESS"]
DASHBOARD=true
RATE_DENY_LIST=
MAX_REQ_PER_SECOND=
MAX_CHECKSUM_LENGTH=
LOG_LEVEL=
HTTP_API_PORT=8000

## p2p

P2P_ENABLE_IPV4=true
P2P_ENABLE_IPV6=false
P2P_ipV4BindAddress=0.0.0.0
P2P_ipV4BindTcpPort=9000
P2P_ipV4BindWsPort=9001
P2P_ipV6BindAddress=::
P2P_ipV6BindTcpPort=9002
P2P_ipV6BindWsPort=9003
P2P_ANNOUNCE_ADDRESSES=["/dns4/$SERVER_IP/tcp/9000/p2p/YOUR_NODE_ID_HERE", "/dns4/$SERVER_IP/ws/tcp/9001", "/dns6/$SERVER_IP/tcp/9002/p2p/YOUR_NODE_ID_HERE", "/dns6/$SERVER_IP/ws/tcp/9003"]
P2P_ANNOUNCE_PRIVATE=
P2P_pubsubPeerDiscoveryInterval=
P2P_dhtMaxInboundStreams=
P2P_dhtMaxOutboundStreams=
P2P_mDNSInterval=
P2P_connectionsMaxParallelDials=
P2P_connectionsDialTimeout=
P2P_ENABLE_UPNP=
P2P_ENABLE_AUTONAT=
P2P_ENABLE_CIRCUIT_RELAY_SERVER=
P2P_ENABLE_CIRCUIT_RELAY_CLIENT=
P2P_BOOTSTRAP_NODES=
P2P_FILTER_ANNOUNCED_ADDRESSES=
EOF

  echo ".env file is created and populated."

  # Starting a node
  docker run --env-file .env -e 'getP2pNetworkStats' -p 8000:8000 -p 9000:9000 -p 9001:9001 -p 9002:9002 -p 9003:9003  ocean-node:mybuild
}

keep_download() {
  echo -e 'Если вы выдруг забыли свой nodeID (peerID), то вводите в браузере http://АЙПИ_ВАШЕГО_СЕРВЕРА:8000/dashboard и ищите ваш nodeID\n'

  read -p "Введите ваш nodeID: " nodeID

  cd
  cd ocean-node/

  sed -i "s/YOUR_NODE_ID_HERE/$nodeID/g" .env

  container_id=$(docker ps -a | grep Exited | awk '{print $1}')
  docker rm $container_id

  docker run --env-file .env -e 'getP2pNetworkStats' -p 8000:8000 -p 9000:9000 -p 9001:9001 -p 9002:9002 -p 9003:9003  ocean-node:mybuild
}

check_logs() {
  logs_to_check=$(docker ps -a | grep 'ocean-node:mybuild' | awk '{print $1}')
  docker logs $logs_to_check --tail 300 -f
}

restart_containers() {
  docker stop $(docker ps -a | grep 'ocean-node:mybuild' | awk '{print $1}')
  docker stop $(docker ps -a | grep 'typesense/typesense' | awk '{print $1}')
  sleep 1
  docker start $(docker ps -a | grep 'ocean-node:mybuild' | awk '{print $1}')
  docker start $(docker ps -a | grep 'typesense/typesense' | awk '{print $1}')
}

fix_peer() {
  read -p "Введите ваш nodeID (peerID): " value_node

  url="https://incentive-backend.oceanprotocol.com/nodes?page=1&size=10&search=$value_node"

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

      docker stop $(docker ps -a | grep 'ocean-node:mybuild' | awk '{print $1}')
      docker stop $(docker ps -a | grep 'typesense/typesense' | awk '{print $1}')
      sleep 1
      docker start $(docker ps -a | grep 'ocean-node:mybuild' | awk '{print $1}')
      docker start $(docker ps -a | grep 'typesense/typesense' | awk '{print $1}')

      echo "Выполнились"
    fi


    sleep 7200  # 2 hours
  done
}

try_to_fix() {
  docker stop $(docker ps -a | grep 'ocean-node:mybuild' | awk '{print $1}')
  docker stop $(docker ps -a | grep 'typesense/typesense' | awk '{print $1}')
  
  ENV_FILE="$HOME/ocean-node/.env"

  SERVER_IP=$(grep -oP '(?<=/dns4/)[^/]*' "$ENV_FILE" | head -1)

  if [[ -z "$SERVER_IP" ]]; then
    echo "Не удалось найти IP-адрес в P2P_ANNOUNCE_ADDRESSES"
    exit 1
  fi

  sed -i "s|P2P_ANNOUNCE_ADDRESSES=.*|P2P_ANNOUNCE_ADDRESSES=[\"/ip4/$SERVER_IP/tcp/9000\", \"/ip4/$SERVER_IP/ws/tcp/9001\"]|" "$ENV_FILE"

  echo "Строка P2P_ANNOUNCE_ADDRESSES обновлена с использованием IP: $SERVER_IP"

  docker start $(docker ps -a | grep 'ocean-node:mybuild' | awk '{print $1}')
  docker start $(docker ps -a | grep 'typesense/typesense' | awk '{print $1}')
}

reinstall_node() {
  read -p "Вы уверены? (CTRL+C чтобы выйти): " checkjust

  docker stop $(docker ps -a | grep 'ocean-node:mybuild' | awk '{print $1}')
  docker stop $(docker ps -a | grep 'typesense/typesense' | awk '{print $1}')

  cd $HOME

  sudo rm -r ocean-node/
  sudo rm -r typesense-data/

  docker rm $(docker ps -a | grep 'typesense/typesense' | awk '{print $1}')
  docker rm $(docker ps -a | grep 'ocean-node:mybuild' | awk '{print $1}')
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. Установить ноду"
    echo "2. Продолжить установку ноды"
    echo "3. Посмотреть логи"
    echo "4. Перезапустить ноду"
    echo "5. Запустить скрипт по авто-перезапуску"
    echo "6. Попытаться исправить способом от админов"
    echo "7. Удалить ноду"
    echo -e "8. Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        keep_download
        ;;
      3)
        check_logs
        ;;
      4)
        restart_containers
        ;;
      5)
        fix_peer
        ;;
      6)
        try_to_fix
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
