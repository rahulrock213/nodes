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

  echo "Удаление старых версий Docker..."
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y "$pkg"
    if [ $? -eq 0 ]; then
      echo "$pkg успешно удален."
    else
      echo "Ошибка при удалении $pkg. Пропускаем..."
    fi
  done

  sudo apt install curl git build-essential jq pkg-config software-properties-common dos2unix ubuntu-desktop desktop-file-utils -y

  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker $USER
  
  sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  sudo rm get-docker.sh

  sudo apt update -y
  sudo systemctl start gdm

  wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip
  unzip openledger-node-1.0.0-linux.zip
  sudo dpkg -i openledger-node-1.0.0.deb

  echo "Запускаем OpenLedger..."
  openledger-node --no-sandbox
}

launch_node() {
  echo "Запускаем OpenLedger..."
  openledger-node --no-sandbox
}

check_logs() {
  docker logs opl_worker
}

delete_node() {
  echo "Удаляем OpenLedger..."

  sudo rm openledger-node-1.0.0.deb
  sudo rm openledger-node-1.0.0-linux.zip

  sudo apt-get remove -y openledger-node

  echo "OpenLedger удален."
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. ✅ Установить ноду"
    echo "2. 🚀 Запустить ноду"
    echo "3. 📄 Проверить логи"
    echo "4. ❌ Удалить ноду"
    echo -e "5. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        launch_node
        ;;
      3)
        check_logs
        ;;
      4)
        delete_node
        ;;
      5)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
