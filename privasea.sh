#!/bin/bash

channel_logo() {
  echo -e '\033[0;31m'
  echo -e '┌┐ ┌─┐┌─┐┌─┐┌┬┐┬┬ ┬  ┌─┐┬ ┬┌┐ ┬┬  '
  echo -e '├┴┐│ ││ ┬├─┤ │ │└┬┘  └─┐└┬┘├┴┐││  '
  echo -e '└─┘└─┘└─┘┴ ┴ ┴ ┴ ┴   └─┘ ┴ └─┘┴┴─┘'
  echo -e '\e[0m'
  echo -e "\n\nПодпишись на самый 4ekHyTbIu* канал в крипте @bogatiy_sybil [💸]"
}

download_node() {
  if [ -d "$HOME/privasea" ]; then
    echo "Папка privasea уже существует. Удалите ноду и установите заново. Выход..."
    return 0
  fi

  echo 'Начинаю установку...'

  cd $HOME

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install nano git gnupg lsb-release apt-transport-https jq screen ca-certificates curl -y

  if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
  else
    echo "Docker уже установлен. Пропускаем"
  fi

  if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  else
    echo "Docker-Compose уже установлен. Пропускаем"
  fi

  docker pull privasea/acceleration-node-beta

  mkdir -p $HOME/privasea/config && cd $HOME/privasea

  docker run -it -v "$HOME/privasea/config:/app/config"  \
    privasea/acceleration-node-beta:latest ./node-calc new_keystore

  cd $HOME/privasea/config

  name_file=$(ls)

  mv ./$name_file ./wallet_keystore

  echo 'Следуйте дальше инструкциям в гайде.'
}

launch_node() {
  read -p "Введите ваш пароль, который вы создали для ноды: " NODE_PASSWORD

  cd $HOME/privasea/

  docker run -d -v "$HOME/privasea/config:/app/config" \
    -e KEYSTORE_PASSWORD=$NODE_PASSWORD \
    privasea/acceleration-node-beta:latest
}

check_wallet() {
  cd $HOME/privasea/config

  ADDRESS=$(jq -r '.address' wallet_keystore)
  echo "Ваш адрес: 0x$ADDRESS"
}

check_logs() {
  docker logs --tail 100 $(docker ps --filter "ancestor=privasea/acceleration-node-beta:latest" --filter "status=running" --format "{{.ID}}")
}

restart_node() {
  RUNNING_CONTAINER=$(docker ps --filter "ancestor=privasea/acceleration-node-beta:latest" --filter "status=running" --format "{{.ID}}")

  if [ ! -z "$RUNNING_CONTAINER" ]; then
      echo "Перезапускаем работающий контейнер..."
      docker restart $RUNNING_CONTAINER
  else
      EXITED_CONTAINER=$(docker ps --filter "ancestor=privasea/acceleration-node-beta:latest" --filter "status=exited" --format "{{.ID}}" --latest)
      
      if [ ! -z "$EXITED_CONTAINER" ]; then
          echo "Перезапускаем последний остановленный контейнер..."
          docker restart $EXITED_CONTAINER
      else
          echo "Не найдено подходящих контейнеров для перезапуска"
      fi
  fi
}

stop_node() {
  docker stop $(docker ps --filter "ancestor=privasea/acceleration-node-beta:latest" --filter "status=running" --format "{{.ID}}")
}

delete_node() {
  read -p 'Если уверены удалить ноду, введите любую букву (CTRL+C чтобы выйти): ' checkjust

  echo 'Начинаю удалять ноду...'

  container_id=$(docker ps --filter "ancestor=privasea/acceleration-node-beta:latest" --filter "status=running" --format "{{.ID}}")

  docker stop $container_id
  docker rm $container_id

  cd $HOME

  sudo rm -r privasea/

  echo 'Нода была удалена.'
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. ⚙️ Установить ноду"
    echo "2. 🚀 Запустить ноду"
    echo "3. 👛 Проверить кошелек"
    echo "4. 📜 Проверить логи"
    echo "5. 🔁 Перезапустить ноду"
    echo "6. 🛑 Остановить ноду"
    echo "7. 🗑️ Удалить ноду"
    echo "8. 🚪 Выйти из скрипта"
    echo -e "\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        launch_node
        ;;
      3)
        check_wallet
        ;;
      4)
        check_logs
        ;;
      5)
        restart_node
        ;;
      6)
        stop_node
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
