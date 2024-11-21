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

  cd $HOME

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install screen nano git curl build-essential make lsof wget jq -y

  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
  sudo apt-get install -y nodejs

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
  source ~/.bashrc

  curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash
  source ~/.bashrc

  cd $HOME
  source /root/.bashrc

  gaianet init --config https://raw.gaianet.ai/qwen2-0.5b-instruct/config.json

  curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install_v2.sh | bash -s -- -v 0.13.5 --noavx

  gaianet start


  mkdir bot
  cd bot
  git clone https://github.com/0xdmimaz/gaianet/
  cd gaianet
  npm i

  gaianet info

  read -p "Введите ваш Node ID: " NEW_ID
  sed -i "s/0x0aa110d2e3a2f14fc122c849cea06d1bc9ed1c62/$NEW_ID/g" config.json

  sed -i 's/const CHUNK_SIZE = 5;/const CHUNK_SIZE = 1;/g' bot_gaia.js

  screen -dmS gaianetnode bash -c '
    echo "Начало выполнения скрипта в screen-сессии"

    node bot_gaia.js

    exec bash
  '

  echo "Screen сессия 'gaianetnode' создана..."
}

check_states() {
  gaianet info
}

check_logs() {
  screen -r gaianetnode
}

update_node() {
  cd $HOME

  curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --upgrade

  echo 'Нода обновилась...'
}

start_node() {
  gaianet start
}

stop_node() {
  gaianet stop
}

delete_node() {
  cd $HOME
  curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/uninstall.sh' | bash
  sudo rm -r bot/
  sudo rm -r gaianet/
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. ✨ Установить ноду"
    echo "2. 📊 Посмотреть данные"
    echo "3. 🟦 Посмотреть логи"
    echo "4. 🔄 Обновить ноду"
    echo "5. 🚀 Запустить ноду"
    echo "6. 🛑 Остановить ноду"
    echo "7. 🗑️ Удалить ноду"
    echo -e "8. 👋 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_states
        ;;
      3)
        check_logs
        ;;
      4)
        update_node
        ;;
      5)
        start_node
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
