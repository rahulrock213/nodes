channel_logo() {
  echo -e '\033[0;31m'
  echo -e '┌┐ ┌─┐┌─┐┌─┐┌┬┐┬┬ ┬  ┌─┐┬ ┬┌┐ ┬┬  '
  echo -e '├┴┐│ ││ ┬├─┤ │ │└┬┘  └─┐└┬┘├┴┐││  '
  echo -e '└─┘└─┘└─┘┴ ┴ ┴ ┴ ┴   └─┘ ┴ └─┘┴┴─┘'
  echo -e '\e[0m'
  echo -e "\n\nПодпишись на самый 4ekHyTbIu* канал в крипте @bogatiy_sybil [💸]"
}

download_node() {
  echo 'Начинаю установку ноды...'

  sudo apt update && sudo apt upgrade -y

  sudo apt install gnupg lsb-release apt-transport-https ca-certificates nano curl jq software-properties-common -y
  
  if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
    echo "Docker и Docker Compose уже установлены."
  else
    echo "Установка Docker и Docker Compose..."

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

    echo "Docker и Docker Compose успешно установлены."
  fi

  docker pull nillion/verifier:v1.0.1 || echo 'Docker не был установлен'
  mkdir -p nillion/verifier
  docker run -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 initialise
}

check_all_states() {
  priv_key=$(jq -r '.priv_key' nillion/verifier/credentials.json)
  pub_key=$(jq -r '.pub_key' nillion/verifier/credentials.json)
  nillion_address=$(jq -r '.address' nillion/verifier/credentials.json)

  echo "Приватный ключ: $priv_key"
  echo "public_key: $pub_key"
  echo "verifier id (nillion address): $nillion_address"
}

launch_node() {
  echo 'Запускаю ноду...'

  docker run -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint "https://testnet-nillion-rpc.lavenderfive.com"
}

restart_not_working_logs() {
  logs_to_check=$(docker ps --filter "ancestor=nillion/verifier:v1.0.1" --filter "status=exited" --format "{{.ID}}" --latest)
  docker restart $logs_to_check
  docker logs $logs_to_check
}

check_node_logs() {
  logs_to_check=$(docker ps --filter "ancestor=nillion/verifier:v1.0.1" --filter "status=running" --format "{{.ID}}" --latest)
  docker logs $logs_to_check --tail 700 -f
}

restart_node() {
  logs_to_check=$(docker ps -a | grep 'nillion/verifier' | awk '{print $1}')
  docker restart $logs_to_check
}

delete_node() {
  read -p 'Если уверены удалить ноду, введите любую букву (CTRL+C чтобы выйти): ' checkjust

  logs_to_check=$(docker ps -a | grep 'nillion/verifier' | awk '{print $1}')
  docker stop $logs_to_check
  docker rm $logs_to_check

  cd $HOME
  sudo rm -r nillion/
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🛠️ Установить ноду"
    echo "2. 📊 Посмотреть все данные"
    echo "3. 🚀 Запустить ноду"
    echo "4. 🌊 Перезапустить неработающий Docker"
    echo "5. 📜 Посмотреть логи"
    echo "6. 🔄 Перезапустить Nillion контейнеры"
    echo "7. 🗑️ Удалить ноду"
    echo -e "8. ❌ Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_all_states
        ;;
      3)
        launch_node
        ;;
      4)
        restart_not_working_logs
        ;;
      5)
        check_node_logs
        ;;
      6)
        restart_node
        ;;
      7)
        delete_node
        ;;
      8)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
