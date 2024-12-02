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

  ports=(5001 8080 4001 27017 31333)

  for port in "${ports[@]}"; do
    if [[ $(lsof -i :"$port" | wc -l) -gt 0 ]]; then
      echo "Ошибка: Порт $port занят. Программа не сможет выполниться."
      exit 1
    fi
  done

  echo -e "Все порты свободны! Сейчас начнется установка...\n"

  sudo apt update -y && sudo apt upgrade -y
  sudo apt install curl jq ca-certificates nano software-properties-common make gnupg lsb-release  -y

  if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
  else
    echo "Docker уже установлен, пропускаем установку..."
  fi

  if ! command -v docker-compose &> /dev/null; then
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  else
    echo "Docker-compose уже установлен, пропускаем установку..."
  fi
  sudo apt-get install -y docker-buildx-plugin docker-compose-plugin

  echo 'Нода была установлена, переходите следуйте дальше по гайду.'
}

launch_node() {
  REF_CODE="nesa120ywlaxmtlqr537f9z788wv9vjpa7hpcl98kh0" bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)
}

check_node_id() {
  cat $HOME/.nesa/identity/node_id.id
  echo
}

check_logs() {
  docker logs orchestrator -f --tail 300
}

check_priv_key() {
  file="$HOME/.nesa/env/orchestrator.env"
  priv_key=$(grep -oP '^NODE_PRIV_KEY="\K[^"]+' "$file")

  echo $priv_key
}

restart_node() { 
  echo 'Делаю перезагрузку...'

  docker restart orchestrator mongodb docker-watchtower-1 ipfs_node

  echo 'Перезагрузка была выполнена.'
}

stop_node() {
  echo 'Начинаю остановку...'

  docker stop orchestrator mongodb docker-watchtower-1 ipfs_node

  echo 'Нода были остановлена.'
}

delete_node() {
  read -p 'Если уверены удалить ноду, введите любую букву (CTRL+C чтобы выйти): ' checkjust

  echo 'Начинаю удалять ноду...'

  cd $HOME
  sudo docker stop orchestrator
  sudo docker stop ipfs_node
  sudo docker rm orchestrator
  sudo docker rm ipfs_node
  sudo docker images
  sudo docker rmi ghcr.io/nesaorg/orchestrator:devnet-latest
  sudo docker rmi ipfs/kubo:latest
  sudo docker image prune -a
  sudo rm -r .nesa/

  echo 'Нода была удалена.'
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🌟 Установить ноду"
    echo "2. 🚀 Запустить ноду"
    echo '3. 🆔 Посмотреть Node ID'
    echo '4. 📜 Посмотреть логи'
    echo '5. 🔑 Посмотреть приватный ключ'
    echo "6. 🔄 Перезагрузить ноду"
    echo '7. 🛑 Остановить ноду'
    echo "8. ❌ Удалить ноду"
    echo -e "9. 👋 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        launch_node
        ;;
      3)
        check_node_id
        ;;
      4)
        check_logs
        ;;
      5)
        check_priv_key
        ;;
      6)
        restart_node
        ;;
      7)
        stop_node
        ;;
      8)
        delete_node
        ;;
      9)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
