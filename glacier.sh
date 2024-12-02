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
  sudo apt-get install nano jq make software-properties-common make gnupg lsb-release ca-certificates curl

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update -y && sudo apt install -y docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker $USER
  newgrp docker
  sudo apt install -y docker-buildx-plugin docker-compose-plugin

  sudo apt install docker.io -y

  read -p "Введите ваш приватный ключ кошелька: " priv_key
  docker run -d -e PRIVATE_KEY=$priv_key --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.2

  if [ $? -eq 0 ]; then
    echo "Контейнер glacier-verifier успешно запущен."
  else
    echo "Ошибка запуска контейнера. Проверьте вводные данные."
  fi
}

check_logs() {
  docker logs -f glacier-verifier --tail 300
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
    echo "3. 🔄 Перезагрузить ноду"
    echo "4. 🛑 Остановить ноду"
    echo "5. 🗑️ Удалить ноду"
    echo -e "6. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_logs
        ;;
      3)
        restart_node
        ;;
      4)
        stop_node
        ;;
      5)
        delete_node
        ;;
      6)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
