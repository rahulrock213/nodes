channel_logo() {
  echo -e '\033[0;31m'
  echo -e '┌┐ ┌─┐┌─┐┌─┐┌┬┐┬┬ ┬  ┌─┐┬ ┬┌┐ ┬┬  '
  echo -e '├┴┐│ ││ ┬├─┤ │ │└┬┘  └─┐└┬┘├┴┐││  '
  echo -e '└─┘└─┘└─┘┴ ┴ ┴ ┴ ┴   └─┘ ┴ └─┘┴┴─┘'
  echo -e '\e[0m'
  echo -e "\n\nПодпишись на самый 4ekHyTbIu* канал в крипте @bogatiy_sybil [💸]"
}

find_file_path() {
  local search_path="$1"
  find "$search_path" -type f -name "filesystem.js" 2>/dev/null | grep "systeminformation/lib/filesystem.js" | head -n 1
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

        # Define the file path
        FILE="/usr/lib/node_modules/rivalz-node-cli/node_modules/systeminformation/lib/filesystem.js"

        # Check if the file exists
        if [ ! -f "$FILE" ]; then
          echo "File not found at $FILE. Attempting to locate it..."
          FILE=$(find_file_path "/usr/lib")

          if [ -z "$FILE" ]; then
            FILE=$(find_file_path "/usr/local/lib")
          fi

          if [ -z "$FILE" ]; then
            FILE=$(find_file_path "/opt")
          fi

          if [ -z "$FILE" ]; then
            # Adding check for ~/.nvm path
            FILE=$(find_file_path "$HOME/.nvm")
          fi

          if [ -z "$FILE" ]; then
            echo "Error: filesystem.js not found. Make sure npm is installed and the file path is correct."
            exit 1
          fi

          echo "File found at $FILE"
        fi

        # Create a temporary file
        TMP_FILE=$(mktemp)

        # Define the original line and the replacement line
        ORIGINAL_LINE="devices = outJSON.blockdevices.filter(item => { return (item.type === 'disk') && item.size > 0 && (item.model !== null || (item.mountpoint === null && item.label === null && item.fstype === null && item.parttype === null && item.path && item.path.indexOf('/ram') !== 0 && item.path.indexOf('/loop') !== 0 && item['disc-max'] && item['disc-max'] !== 0)); });"
        NEW_LINE="devices = outJSON.blockdevices.filter(item => { return (item.type === 'disk') && item.size > 0 }).sort((a, b) => b.size - a.size);"

        # Read through the file line by line
        while IFS= read -r line
        do
          if [[ "$line" == *"$ORIGINAL_LINE"* ]]; then
            echo "$NEW_LINE" >> "$TMP_FILE"
          else
            echo "$line" >> "$TMP_FILE"
          fi
        done < "$FILE"

        # Replace the original file with the modified one
        mv "$TMP_FILE" "$FILE"
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
