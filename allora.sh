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
  
  ports=(8000)

  for port in "${ports[@]}"; do
    if [[ $(lsof -i :"$port" | wc -l) -gt 0 ]]; then
      echo "Ошибка: Порт $port занят. Программа не сможет выполниться."
      exit 1
    fi
  done

  echo 'Обновляем систему...'
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 python3 python3-pip expect

  sudo apt-get install nano

  echo 'Docker установка'
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
  sudo curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  docker-compose --version
  
}

keep_download() {
  sudo apt install ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 -y

  # Install Python3
  sudo apt install python3 -y
  python3 --version

  sudo apt install python3-pip -y
  pip3 --version

  # Install Docker
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io -y
  docker --version

  # Install Docker-Compose
  VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)

  sudo curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

  sudo chmod +x /usr/local/bin/docker-compose
  docker-compose --version

  # Docker permission to the user
  sudo groupadd docker
  sudo usermod -aG docker $USER

  # Clone the repository
  git clone https://github.com/allora-network/basic-coin-prediction-node
  cd basic-coin-prediction-node || exit

  # Copy the .env.example to .env
  cp .env.example .env

  # Copy config.example.json to config.json
  cp config.example.json config.json

  # Function to update .env file with user input
  update_env() {
    key=$1
    value=$2
    sed -i "s/^$key=.*/$key=$value/" .env
  }

  # Function to update config.json with user input using jq
  update_config() {
    key=$1
    value=$2
    jq --arg v "$value" ".worker[0].parameters.$key = \$v" config.json > config.tmp.json && mv config.tmp.json config.json
  }

  # Function to update topicId in config.json as an integer
  update_topic_id() {
    key=$1
    value=$2
    jq ".worker[0].$key = $value" config.json > config.tmp.json && mv config.tmp.json config.json
  }

  # Prompt user for the necessary input
  echo "Выберите любую из монет:"
  PS3="Введите ваш выбор (1-5): "
  options=("ETH" "SOL" "BTC" "BNB" "ARB")
  topic_ids=("1" "3" "5" "8" "9")
  select opt in "${options[@]}"; do
    if [[ -n $opt ]]; then
      update_env "TOKEN" "$opt"
      update_config "Token" "$opt"
      update_topic_id "topicId" "${topic_ids[REPLY-1]}"
      break
    fi
  done

  # Prompt for TRAINING_DAYS
  read -p "Введите количество TRAINING_DAYS (Выберите: 2, 31): " training_days
  update_env "TRAINING_DAYS" "$training_days"

  # Prompt for TIMEFRAME based on the training days
  echo "Выберите таймфрейм для TRAINING_DAYS:"
  if [[ $training_days -le 2 ]]; then
    echo "Лучше использовать таймфрейм от >= 30min"
  elif [[ $training_days -le 30 ]]; then
    echo "Лучше использовать таймфрейм от >= 4h"
  else
    echo "Лучше использовать таймфрейм от >= 4d"
  fi
  read -p "Выберите таймфрейм (Выберите:, 30min, 4h, 4d): " timeframe
  update_env "TIMEFRAME" "$timeframe"

  # Prompt for MODEL
  echo "Выберите тренируемую модель:"
  PS3="Введите ваш выбор (1-4): "
  models=("LinearRegression" "SVR" "KernelRidge" "BayesianRidge")
  select model in "${models[@]}"; do
    if [[ -n $model ]]; then
      update_env "MODEL" "$model"
      break
    fi
  done

  # Prompt for REGION
  echo "Выберите ваш регион:"
  PS3="Введите ваш выбор (1-2): "
  regions=("EU" "US")
  select region in "${regions[@]}"; do
    if [[ -n $region ]]; then
      update_env "REGION" "$region"
      break
    fi
  done

  # Prompt for DATA_PROVIDER
  echo "Выберите API провайдера:"
  PS3="Введите ваш выбор (1-2): "
  providers=("Binance" "Coingecko")
  select provider in "${providers[@]}"; do
    if [[ -n $provider ]]; then
      update_env "DATA_PROVIDER" "$provider"
      break
    fi
  done

  # Prompt for CG_API_KEY if Coingecko is selected
  if [[ $provider == "Coingecko" ]]; then
    read -p "Введите ваш Coingecko API Key: " cg_api_key
    update_env "CG_API_KEY" "$cg_api_key"
  else
    update_env "CG_API_KEY" ""
  fi

  # Prompt for wallet name and seed phrase
  read -p "Ваше имя кошелька: " wallet_name
  read -p "Ваша сид-фраза: " seed_phrase

  # Update config.json with wallet name and seed phrase
  jq --arg wallet "$wallet_name" --arg seed "$seed_phrase" \
  '.wallet.addressKeyName = $wallet | .wallet.addressRestoreMnemonic = $seed' config.json > config.tmp.json && mv config.tmp.json config.json

  # Make init.config executable and run it
  chmod +x init.config
  ./init.config

  # Start Docker containers and build
  docker compose up --build -d

  # Output completion message
  echo "Ваша нода начала работать."
}

node_reload() {
  cd basic-coin-prediction-node/
  docker compose down
  docker compose build
  docker compose up -d 
  cd
}

check_logs_docker() {
  cd basic-coin-prediction-node/
  docker compose logs -f
  cd
}

check_logs_worker() {
  cd basic-coin-prediction-node/
  docker compose logs worker
  cd
}

update_node() {
  cd basic-coin-prediction-node/
  docker compose down
  docker compose pull
  docker compose build
  docker compose up -d
  cd
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. Обновить компоненты"
    echo "2. Установка ноды"
    echo "3. Перезапустить ноду"
    echo "4. Проверить логи ноды"
    echo "5. Проверить логи воркера"
    echo "6. Обновить версию ноды"
    echo -e "7. Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        keep_download
        ;;
      3)
        node_reload
        ;;
      4)
        check_logs_docker
        ;;
      5)
        check_logs_worker
        ;;
      6)
        update_node
        ;;
      7)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
