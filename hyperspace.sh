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

  read -p "Введите ваш приватный ключ: " PRIVATE_KEY
  echo $PRIVATE_KEY > $HOME/my.pem

  session="hyperspacenode"

  cd $HOME

  sudo apt-get update -y && sudo apt-get upgrade -y
  sudo apt-get install wget make tar screen nano libssl3-dev build-essential unzip lz4 gcc git jq -y

  packages="wget make tar screen nano libssl3-dev build-essential unzip lz4 gcc git jq"

  check_and_install() {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
      sudo apt-get install "$1" -y
    fi
  }

  for package in $packages; do
    check_and_install "$package"
  done

  if [ -d "$HOME/.aios" ]; then
    sudo rm -rf "$HOME/.aios"
    aios-cli kill
  fi

  if [ -d "$HOME/.aios" ]; then
    sudo rm -rf "$HOME/.aios"
    aios-cli kill
  fi
  
  if screen -list | grep -q "\.${session}"; then
    screen -S hyperspacenode -X quit
  else
    echo "Сессия ${session} не найдена."
  fi

  while true; do
    curl -s https://download.hyper.space/api/install | bash | tee $HOME/hyperspacenode_install.log

    if ! grep -q "Failed to parse version from release data." $HOME/hyperspacenode_install.log; then
        echo "Клиент-скрипт был установлен."
        break
    else
        echo "Сервер установки клиента недоступен, повторим через 30 секунд..."
        sleep 30
    fi
  done

  rm hyperspacenode_install.log

  export PATH=$PATH:$HOME/.aios
  source ~/.bashrc

  eval "$(cat ~/.bashrc | tail -n +10)"

  screen -dmS hyperspacenode bash -c '
    echo "Начало выполнения скрипта в screen-сессии"

    aios-cli start

    exec bash
  '

  while true; do
    aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf 2>&1 | tee $HOME/hyperspacemodel_download.log

    if grep -q "Download complete" $HOME/hyperspacemodel_download.log; then
        echo "Модель была установлен."
        break
    else
        echo "Сервер установки модели недоступен, повторим через 30 секунд..."
        sleep 30
    fi
  done

  rm hyperspacemodel_download.log

  aios-cli hive import-keys $HOME/my.pem
  aios-cli hive login
  aios-cli hive connect
}

check_logs() {
  screen -S hyperspacenode -X hardcopy /tmp/screen_log.txt && sleep 0.1 && tail -n 100 /tmp/screen_log.txt && rm /tmp/screen_log.txt
}

check_points() {
  aios-cli hive points
}

start_points_monitor() {
    echo "Запускаем проверку поинтов..."

    PIDS=$(ps aux | grep "[p]oints_monitor_hyperspace.sh" | awk '{print $2}')

    for PID in $PIDS; do
        kill -9 $PID
        echo "Процесс с PID $PID завершен"
    done

    cat > $HOME/points_monitor_hyperspace.sh << 'EOL'
#!/bin/bash
LOG_FILE="$HOME/aios-cli.log"
SCREEN_NAME="hyperspacenode"
LAST_POINTS="0"

while true; do
    CURRENT_POINTS=$(aios-cli hive points | grep "Points:" | awk '{print $2}')
    
    if [ "$CURRENT_POINTS" = "$LAST_POINTS" ] || { [ "$CURRENT_POINTS" != "NaN" ] && [ "$LAST_POINTS" != "NaN" ] && [ "$CURRENT_POINTS" -eq "$LAST_POINTS" ]; }; then
        echo "$(date): Поинты не были начислены (Текущее: $CURRENT_POINTS, Предыдущее: $LAST_POINTS), сервис перезапускается..." >> $HOME/points_monitor_hyperspace.log
        
        screen -S "$SCREEN_NAME" -X stuff $'\003'
        sleep 5
        screen -S "$SCREEN_NAME" -X stuff "aios-cli kill\n"
        sleep 5
        screen -S "$SCREEN_NAME" -X stuff "aios-cli start --connect"
    fi
    
    LAST_POINTS="$CURRENT_POINTS"
    
    sleep 10800
done
EOL

    chmod +x $HOME/points_monitor_hyperspace.sh

    nohup $HOME/points_monitor_hyperspace.sh > $HOME/points_monitor_hyperspace.log 2>&1 &

    echo 'Проверка поинтов была запущена.'
}

restart_node() {
  session="hyperspacenode"

  PIDS=$(ps aux | grep "[p]oints_monitor_hyperspace.sh" | awk '{print $2}')
    
  for PID in $PIDS; do
    kill -9 $PID
    echo "Процесс с PID $PID завершен"
  done
  
  if screen -list | grep -q "\.${session}"; then
    screen -S "${session}" -p 0 -X stuff "^C"
    sleep 1
    screen -S "${session}" -p 0 -X stuff "aios-cli start --connect\n"
    echo "Нода была перезагружена."
  else
    echo "Сессия ${session} не найдена."
  fi
}

delete_node() {
  read -p 'Если уверены удалить ноду, введите любую букву (CTRL+C чтобы выйти): ' checkjust

  echo 'Начинаю удалять ноду...'

  PIDS=$(ps aux | grep "[p]oints_monitor_hyperspace.sh" | awk '{print $2}')
    
  for PID in $PIDS; do
    kill -9 $PID
    echo "Процесс с PID $PID завершен"
  done

  screen -S hyperspacenode -X quit
  aios-cli kill
  aios-cli models remove hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf
  sudo rm -rf $HOME/.aios

  echo 'Нода была удалена.'
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🙂 Установить ноду"
    echo "2. 📜 Посмотреть логи"
    echo "3. ⭐ Узнать сколько поинтов"
    echo "4. ✅ Автоматическая проверка поинтов"
    echo "5. 🔄 Перезагрузить ноду"
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
        check_points
        ;;
      4)
        start_points_monitor
        ;;
      5)
        restart_node
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
