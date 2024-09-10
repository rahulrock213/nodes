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
    echo "1. Установить ноду"
    echo '2. Посмотреть логи'
    echo '3. Посмотреть приватный ключ'
    echo '4. Обновить ноду'
    echo -e "5. Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice
    
    case $choice in
      1)
        echo 'Начинаем обновлять систему'
        sudo apt-get update -y
        sudo apt upgrade -y
        sudo apt-get install make build-essential pkg-config libssl-dev unzip tar lz4 gcc git jq -y

        echo 'Скачиваем репозиторий'
        wget https://github.com/fractal-bitcoin/fractald-release/releases/download/v0.2.1/fractald-0.2.1-x86_64-linux-gnu.tar.gz
        tar -zxvf fractald-0.2.1-x86_64-linux-gnu.tar.gz 

        echo 'Начинаем процесс...'
        cd fractald-0.2.1-x86_64-linux-gnu/
        mkdir data
        cp ./bitcoin.conf ./data

        echo 'Создаем сервисный файл...'
        sudo tee /etc/systemd/system/fractald.service > /dev/null << EOF
[Unit]
Description=Fractal Node
After=network-online.target

[Service]
User=$USER
ExecStart=/root/fractald-0.2.1-x86_64-linux-gnu/bin/bitcoind -datadir=/root/fractald-0.2.1-x86_64-linux-gnu/data/ -maxtipage=504576000
Restart=always
RestartSec=5
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

        echo 'Создаем кошелек...'
        echo '-------------------------------------------'
        cd bin
        ./bitcoin-wallet -wallet=wallet -legacy create
        echo '-------------------------------------------'

        cd /root/fractald-0.2.1-x86_64-linux-gnu/bin
        ./bitcoin-wallet -wallet=/root/.bitcoin/wallets/wallet/wallet.dat -dumpfile=/root/.bitcoin/wallets/wallet/MyPK.dat dump

        echo 'ЗАПИШИТЕ ПРИВАТНЫЙ КЛЮЧ КОШЕЛЬКА:'
        sleep 10
        echo '-------------------------------------------'
        cd && awk -F 'checksum,' '/checksum/ {print "Wallet Private Key:" $2}' .bitcoin/wallets/wallet/MyPK.dat
        echo '-------------------------------------------'
        echo 'Начинаем перезагрузку сервесных файлов...'
        sleep 10
        
        sudo systemctl daemon-reload
        sudo systemctl enable fractald
        sudo systemctl start fractald
        ;;
	    2)
        sudo journalctl -u fractald -fo cat
        ;;
      3)
        echo "Просмотр приватного ключа..."

        cd /root/fractald-0.2.1-x86_64-linux-gnu/bin
        ./bitcoin-wallet -wallet=/root/.bitcoin/wallets/wallet/wallet.dat -dumpfile=/root/.bitcoin/wallets/wallet/MyPK.dat dump
        awk -F 'checksum,' '/checksum/ {print "Приватный ключ твоего кошелька:" $2}' /root/.bitcoin/wallets/wallet/MyPK.dat
        sleep 5
        ;;
      4)
        echo "Начинаем обновление скрипта..."

            # Резервное копирование директории data
            echo "Резервное копирование директории data..."
            sudo cp -r /root/fractald-0.1.8-x86_64-linux-gnu/data /root/fractal-data-backup

            echo "Удаление прошлой версии..."
            sudo systemctl stop fractald
            sudo systemctl disable fractald
            sudo rm /etc/systemd/system/fractald.service
            sudo systemctl daemon-reload
            rm -rf /root/fractald-0.1.8-x86_64-linux-gnu

            # Загрузка новой версии библиотеки fractald
            echo "Загрузка новой версии библиотеки fractald..."
            wget https://github.com/fractal-bitcoin/fractald-release/releases/download/v0.2.1/fractald-0.2.1-x86_64-linux-gnu.tar.gz

            # Извлечение новой версии библиотеки fractald
            echo "Извлечение новой версии библиотеки fractald..."
            tar -zxvf fractald-0.2.1-x86_64-linux-gnu.tar.gz

            # Переход в директорию новой версии fractald
            echo "Переход в директорию новой версии fractald..."
            cd fractald-0.2.1-x86_64-linux-gnu

            # Восстановление данных из резервной копии
            echo "Восстановление данных из резервной копии..."
            cp -r /root/fractal-data-backup /root/fractald-0.2.1-x86_64-linux-gnu/

            # Обновление файла службы systemd (если есть изменения)
            echo "Обновление файла службы systemd..."
            sudo tee /etc/systemd/system/fractald.service > /dev/null <<EOF
[Unit]
Description=Fractal Node
After=network.target
[Service]
User=root
WorkingDirectory=/root/fractald-0.2.1-x86_64-linux-gnu
ExecStart=/root/fractald-0.2.1-x86_64-linux-gnu/bin/bitcoind -datadir=/root/fractald-0.2.1-x86_64-linux-gnu/data/ -maxtipage=504576000
Restart=always
RestartSec=3
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

            # Перезагрузка конфигурации менеджера systemd
            echo "Перезагрузка конфигурации менеджера systemd..."
            sudo systemctl daemon-reload

            # Запуск и установка службы на автозапуск
            echo "Запуск и включение службы fractald..."
            sudo systemctl enable fractald
            sudo systemctl start fractald

            echo "Обновление скрипта завершено."
        ;;
      5)
        exit 0
        ;;
      *)
        echo "Неверная пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
