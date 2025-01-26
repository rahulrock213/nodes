channel_logo() {
  echo -e '\033[0;31m'
  echo -e '┌┐ ┌─┐┌─┐┌─┐┌┬┐┬┬ ┬  ┌─┐┬ ┬┌┐ ┬┬  '
  echo -e '├┴┐│ ││ ┬├─┤ │ │└┬┘  └─┐└┬┘├┴┐││  '
  echo -e '└─┘└─┘└─┘┴ ┴ ┴ ┴ ┴   └─┘ ┴ └─┘┴┴─┘'
  echo -e '\e[0m'
  echo -e "\n\nПодпишись на самый 4ekHyTbIu* канал в крипте @bogatiy_sybil [💸]"
}

download_node() {
  if [ -d "$HOME/.titanedge" ]; then
    echo "Папка .titanedge уже существует. Удалите ноду и установите заново. Выход..."
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

  echo 'Необходимые зависимости были установлены. Запустите ноду 2 пунктом.'
}

launch_node() {
  container_id=$(docker ps --filter "ancestor=nezha123/titan-edge" --format "{{.ID}}")

  if [ -n "$container_id" ]; then
    echo "Найден контейнер: $container_id"
    docker stop $container_id
    docker rm $container_id
  fi

  while true; do
    echo -en "Введите ваш HASH:${NC} "
    read HASH
    if [ ! -z "$HASH" ]; then
        break
    fi
    echo 'HASH не может быть пустым.'
  done

  docker run --network=host -d -v ~/.titanedge:/root/.titanedge nezha123/titan-edge
  sleep 10

  docker run --rm -it -v ~/.titanedge:/root/.titanedge nezha123/titan-edge bind --hash=$HASH https://api-test1.container1.titannet.io/api/v2/device/binding
  
  echo -e "Нода была запущена."
}

docker_logs() {
  docker logs $(docker ps --filter "ancestor=nezha123/titan-edge" --format "{{.ID}}")
}

restart_node() {
  docker restart $(docker logs $(docker ps --filter "ancestor=nezha123/titan-edge" --format "{{.ID}}"))
  echo 'Нода была перезагружена.'
}

stop_node() {
  docker stop $(docker logs $(docker ps --filter "ancestor=nezha123/titan-edge" --format "{{.ID}}"))
  echo 'Нода была остановлена.'
}

delete_node() {
  read -p 'Если вы уверены удалить ноду, напишите любой символ (CTRL+C чтобы выйти): ' checkjust

  docker_id=$(docker ps --filter "ancestor=nezha123/titan-edge" --format "{{.ID}}")
  docker stop $docker_id
  docker rm $docker_id

  sudo rm -r $HOME/.titanedge

  echo 'Нода была удалена.'
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🛠️ Установить ноду"
    echo "2. 🚀 Запустить ноду"
    echo "3. 📜 Проверить логи"
    echo "4. 🔄 Перезагрузить ноду"
    echo "5. ⛔ Остановить ноду"
    echo "6. 🗑️ Удалить ноду"
    echo -e "7. ❌ Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        launch_node
        ;;
      3)
        docker_logs
        ;;
      4)
        restart_node
        ;;
      5)
        stop_node
        ;;
      6)
        delete_node
        ;;
      7)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
