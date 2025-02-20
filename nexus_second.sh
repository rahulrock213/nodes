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
  sudo apt-get install nano screen cargo unzip build-essential pkg-config libssl-dev git-all protobuf-compiler jq make software-properties-common ca-certificates curl

  if [ -d "$HOME/.nexus" ]; then
    sudo rm -rf "$HOME/.nexus"
  fi

  if screen -list | grep -q "nexusnode"; then
      screen -S nexusnode -X quit
  fi

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

  source $HOME/.cargo/env
  echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
  rustup update

  rustup target add riscv32i-unknown-none-elf

  PROTOC_VERSION=29.1
  curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOC_VERSION/protoc-$PROTOC_VERSION-linux-x86_64.zip
  unzip protoc-$PROTOC_VERSION-linux-x86_64.zip -d /usr/local
  export PATH="/usr/local/bin:$PATH"

  mkdir -p $HOME/.config/cli

  screen -dmS nexusnode bash -c '
    echo "Начало выполнения скрипта в screen-сессии"

    sudo curl https://cli.nexus.xyz/ | sh

    exec bash
  '

  echo 'Нода была запущена. Переходите в screen сессию. Если захотите обратно вернуться в меню, то НЕ ЗАКРЫВАЙТЕ ЧЕРЕЗ CTRL+C. Иначе заново устанавливайте ноду.'
}

go_to_screen() {
  screen -r nexusnode
}

check_logs() {
  screen -S nexusnode -X hardcopy /tmp/screen_log.txt && sleep 0.1 && tail -n 100 /tmp/screen_log.txt && rm /tmp/screen_log.txt
}

try_to_fix() {
  session="nexusnode"

  echo "Выберите пункт:"
  echo "1) Первый способ"
  echo "2) Второй способ"
  echo "3) Третий способ"
  echo "4) Четвертый способ"
  read -p "Введите номер пункта: " choicee

  case $choicee in
      1)
          screen -S "${session}" -p 0 -X stuff "^C"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "rustup target add riscv32i-unknown-none-elf"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "cd $HOME/.nexus/network-api/clients/cli/"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "cargo run --release -- --start --beta"
          echo 'Проверяйте ваши логи.'
          ;;
      2)
          screen -S "${session}" -p 0 -X stuff "^C"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "~/.nexus/network-api/clients/cli/target/release/nexus-network --start"
          echo 'Проверяйте ваши логи.'
          ;;
      3)
          screen -S "${session}" -p 0 -X stuff "^C"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "cd $HOME/.nexus/network-api/clients/cli/"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "rm build.rs"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "wget https://raw.githubusercontent.com/londrwus/network-api/refs/heads/main/clients/cli/build.rs"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "rustup target add riscv32i-unknown-none-elf"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "cd $HOME/.nexus/network-api/clients/cli/"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "cargo run --release -- --start --beta"
          echo 'Проверяйте ваши логи.'
          ;;
      4)
          screen -S "${session}" -p 0 -X stuff "sudo apt update -y"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "https://github.com/protocolbuffers/protobuf/releases/download/v29.1/protoc-29.1-linux-x86_64.zip"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "unzip protoc-29.1-linux-x86_64.zip -d /usr/local"
          sleep 1
          screen -S "${session}" -p 0 -X stuff "export PATH="/usr/local/bin:$PATH""
          sleep 1
          screen -S "${session}" -p 0 -X stuff "sudo curl https://cli.nexus.xyz/ | sh"
          echo 'Проверяйте ваши логи.'
          ;;
      *)
          echo "Некорректный ввод. Пожалуйста, выберите пункт в меню."
          ;;
  esac
}

make_swap() {
  sudo fallocate -l 10G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

  echo 'Swap был поставлен.'
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
    echo "2. 📂 Перейти в ноду (выйти CTRL+A D)"
    echo "3. 📜 Посмотреть логи"
    echo "4. 😤 Попытаться исправить ошибки"
    echo "5. 🤺 Поставить SWAP"
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
        check_logs
        ;;
      4)
        try_to_fix
        ;;
      5)
        make_swap
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
