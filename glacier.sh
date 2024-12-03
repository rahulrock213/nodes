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

  sudo apt install lsof

  ports=(10801)

  for port in "${ports[@]}"; do
    if [[ $(lsof -i :"$port" | wc -l) -gt 0 ]]; then
      echo "Ошибка: Порт $port занят. Программа не сможет выполниться."
      exit 1
    fi
  done

  echo -e "Все порты свободны! Сейчас начнется установка...\n"

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install nano jq make software-properties-common apt-transport-https make gnupg lsb-release ca-certificates curl

  if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
  else
    echo "Docker уже установлен. Пропускаем"
  fi

  if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  else
    echo "Docker-Compose уже установлен. Пропускаем"
  fi

  read -p "Введите ваш приватный ключ кошелька: " priv_key
  docker run -d -e PRIVATE_KEY=$priv_key --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.3

  if [ $? -eq 0 ]; then
    echo "Контейнер glacier-verifier успешно запущен."
  else
    echo "Ошибка запуска контейнера. Проверьте вводные данные."
  fi
}

check_logs() {
  docker logs -f glacier-verifier --tail 300
}

update_node() {
  echo 'Подождите...'

  docker stop glacier-verifier
  docker rm glacier-verifier

  read -p "Введите ваш приватный ключ кошелька: " priv_key

  read -p "Хотите сохранить приватный ключ на сервере для дальнейших обновлений? (y/n): " save_key

  if [[ $save_key == "y" ]]; then
    echo "$priv_key" > "$HOME/.glacier_key"
    chmod 600 "$HOME/.glacier_key"
    echo "Приватный ключ сохранен в $HOME/.glacier_key"
  else
    echo "Приватный ключ не будет сохранен."
  fi

  docker run -d -e PRIVATE_KEY=$priv_key --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.3

  echo 'Нода была обновлена и запущена.'
}

restart_node() {
  echo 'Начинаю перезагрузку...'

  docker restart glacier-verifier

  echo 'Нода была перезагружена.'
}

stop_node() {
  echo 'Начинаю остановку...'

  docker stop glacier-verifier

  echo 'Нода была остановлена.'
}

delete_node() {
  read -p 'Если уверены удалить ноду, введите любую букву (CTRL+C чтобы выйти): ' checkjust

  echo 'Начинаю удалять ноду...'

  docker stop glacier-verifier
  docker kill glacier-verifier
  docker rm glacier-verifier

  echo 'Нода была удалена.'
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🚀 Установить ноду"
    echo "2. 📜 Посмотреть логи (выйти CTRL+C)"
    echo '3. 🔰 Обновить ноду'
    echo "4. 🔄 Перезагрузить ноду"
    echo "5. 🛑 Остановить ноду"
    echo "6. 🗑️ Удалить ноду"
    echo -e "7. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_logs
        ;;
      3)
        update_node
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
