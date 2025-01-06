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

  sudo apt update -y && sudo apt upgrade -y
  sudo apt install curl git nano make gcc build-essential jq screen ca-certificates gcc unzip lz4 wget bison software-properties-common -y

  curl -fsSL https://ollama.com/install.sh | sh

  wget -O infera "https://drive.google.com/uc?id=1VSeI8cXojdh78H557SQJ9LfnnaS96DT-&export=download&confirm=yes"
  chmod +x ./infera

  screen -dmS inferanode bash -c '
    echo "Начало выполнения скрипта в screen-сессии"

    ./infera
    source ~/.bashrc
    init-infera

    exec bash
  '
}   

check_points() {
  total_points=$(curl http://localhost:11025/points | jq)
  echo -e "У вас столько поинтов: $total_points"
}

link_node() {
  read -p "Введите ваш ACCOUNT ID с сайта infera: " acc_id

  curl -s "http://localhost:11025/link_node/$acc_id"

  echo 'Проверьте, что нода была привязана.'
}

watch_secrets() {
  curl http://localhost:11025/node_details | jq
}

check_logs() {
  screen -S inferanode -X hardcopy /tmp/screen_log.txt && sleep 0.1 && tail -n 100 /tmp/screen_log.txt && rm /tmp/screen_log.txt
}

restart_node() {
  echo 'Начинаю перезагрузку...'

  session="inferanode"
  
  if screen -list | grep -q "\.${session}"; then
    screen -S "${session}" -p 0 -X stuff "^C"
    sleep 1
    screen -S "${session}" -p 0 -X stuff "chmod +x ./infera\n"
    screen -S "${session}" -p 0 -X stuff "./infera\n"
    echo "Нода была перезагружена."
  else
    echo "Сессия ${session} не найдена."
  fi
}

update_node() {
  echo 'Начинаю обновление ноды...'

  if screen -list | grep -q "\.inferanode"; then
    screen -S inferanode -p 0 -X stuff "^C"
    sudo screen -X -S inferanode quit
  fi

  sudo rm -rf ~/infera
  curl -sSL http://downloads.infera.org/infera-linux-amd.sh | bash

  echo 'Нода была обновлена.'
}

delete_node() {
  read -p 'Если уверены удалить ноду, введите любую букву (CTRL+C чтобы выйти): ' checkjust

  echo 'Начинаю удалять ноду...'

  sudo rm -rf ~/infera

  echo 'Нода была уделаена.'
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🌱 Установить ноду"
    echo "2. 📊 Проверить сколько поинтов"
    echo "3. 🌍 Привязать ноду к сайту"
    echo "4. 📂 Посмотреть данные"
    echo "5. 🕸️ Посмотреть логи"
    echo "6. 🍴 Перезагрузить ноду"
    echo "7. 🔄 Обновить ноду"
    echo "8. ❌ Удалить ноду"
    echo -e "9. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_points
        ;;
      3)
        link_node
        ;;
      4)
        watch_secrets
        ;;
      5)
        check_logs
        ;;
      6)
        restart_node
        ;;
      7)
        update_node
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
