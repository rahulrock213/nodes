channel_logo() {
  echo -e '\033[0;31m'
  echo -e '┌┐ ┌─┐┌─┐┌─┐┌┬┐┬┬ ┬  ┌─┐┬ ┬┌┐ ┬┬  '
  echo -e '├┴┐│ ││ ┬├─┤ │ │└┬┘  └─┐└┬┘├┴┐││  '
  echo -e '└─┘└─┘└─┘┴ ┴ ┴ ┴ ┴   └─┘ ┴ └─┘┴┴─┘'
  echo -e '\e[0m'
  echo -e "\n\nПодпишись на самый 4ekHyTbIu* канал в крипте @bogatiy_sybil [💸]"
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. Установить ноду Rivalz"
    echo "2. Обновить ноду"
    echo "3. Поменять кошелек"
    echo "4. Поменять потребляемое кол-во места диска"
    echo "5. Информация о ноде"
    echo "6. Исправить ошибку Running on another..."
    echo "7. Удалить ноду"
    echo -e "8. Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice
    
    case $choice in
      1)
        echo "Начинаю установку ноды..."

        # Upgrade dependencies
        echo "Происходит обновление пакетов..."
        if sudo apt update && sudo apt upgrade -y; then
            echo "Обновление пакетов: Успешно"
        else
            echo "Обновление пакетов: Ошибка"
            exit 1
        fi

        # Screen libary
        echo "Установка screen..."
        if sudo apt-get install screen -y; then
            echo "Установка screen: Успешно"
        else
            echo "Установка screen: Ошибка"
            exit 1
        fi

        # Install node.js
        echo "Скачиваем Node.Js..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        if sudo apt install -y nodejs; then
          echo "Устанвока Node.Js: Успешно"
        else
          echo "Установка Node.Js: Ошибка"
          exit 1
        fi

        # Установка ноды Rivalz
        echo "Установка ноды Rivalz..."
        npm i -g rivalz-node-cli

        rivalz run
        ;;
      2)
        npm i -g rivalz-node-cli@2.6.2

        rivalz run
        ;;
      3)
        rivalz change-wallet
        ;;
      4)
        rivalz change-hardware-config
        ;;
      5)
        rivalz info
        ;;
      6)
        echo "Начинаю делать исправление..."
        rm -f /etc/machine-id
        dbus-uuidgen --ensure=/etc/machine-id
        cp /etc/machine-id /var/lib/dbus/machine-id
        echo "Готово!"
        ;;
      7)
        sudo npm uninstall -g rivalz-node-cli
        ;;
      8)
        exit 0
        ;;
      *)
        echo "Неверная пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
