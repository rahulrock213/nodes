channel_logo() {
  echo -e '\033[0;31m'
  echo -e '┌┐ ┌─┐┌─┐┌─┐┌┬┐┬┬ ┬  ┌─┐┬ ┬┌┐ ┬┬  '
  echo -e '├┴┐│ ││ ┬├─┤ │ │└┬┘  └─┐└┬┘├┴┐││  '
  echo -e '└─┘└─┘└─┘┴ ┴ ┴ ┴ ┴   └─┘ ┴ └─┘┴┴─┘'
  echo -e '\e[0m'
  echo -e "\n\nПодпишись на самый 4ekHyTbIu* канал в крипте @bogatiy_sybil [💸]"
}

download_node() {
  echo 'Начинаю установку...'

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install nano screen cargo build-essential pkg-config libssl-dev git-all protobuf-compiler jq make software-properties-common ca-certificates curl

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

  source $HOME/.cargo/env
  echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
  rustup update

  screen -dmS nexusnode bash -c '
    echo "Начало выполнения скрипта в screen-сессии"

    sudo curl https://cli.nexus.xyz/ | sh

    exec bash
  '
}

go_to_screen() {
  screen -r nexusnode
}

check_prover_id() {
  prover_id=$(cat ~/.nexus/prover-id)
  echo -e "Ваш PROVER ID: $prover_id"
}

change_prover_id() {
  read -p "Введите ваш Prover id: " new_prover_id

  file_path="$HOME/.nexus/prover-id"

  if [ -f "$file_path" ]; then
      echo "$new_prover_id" > "$file_path"
      echo "Prover id успешно обновлен."
      restart_node
  else
      echo "Файл $file_path не найден."
  fi
}

check_logs() {
  screen -S nexusnode -X hardcopy /tmp/screen_log.txt && sleep 0.1 && tail -n 100 /tmp/screen_log.txt && rm /tmp/screen_log.txt
}

restart_node() {
  echo 'Начинаю перезагрузку...'

  session="nexusnode"
  
  if screen -list | grep -q "\.${session}"; then
    screen -S "${session}" -p 0 -X stuff "^C"
    sleep 1
    screen -S "${session}" -p 0 -X stuff "sudo curl https://cli.nexus.xyz/ | sh\n"
    echo "Нода была перезагружена."
  else
    echo "Сессия ${session} не найдена."
  fi
}

delete_node() {
  screen -S nexusnode -X quit
  sudo rm -r $HOME/.nexus/
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🛠️ Установить ноду"
    echo "2. 📂 Перейти в ноду (выйти CTRL+A D)"
    echo "3. 🆔 Посмотреть PROVER ID"
    echo "4. 🆔 Поменять PROVER ID"
    echo "5. 📜 Посмотреть логи"
    echo "6. 🔄 Перезапустить ноду"
    echo "7. ❌ Удалить ноду"
    echo -e "8. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        go_to_screen
        ;;
      3)
        check_prover_id
        ;;
      4)
        change_prover_id
        ;;
      5)
        check_logs
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
