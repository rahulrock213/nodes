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

  sudo apt-get update -y && sudo apt upgrade -y 
  sudo apt install curl git nano screen make jq build-essential gcc unzip wget lz4 aria2 -y

  cd $HOME
  ver="1.22.0"
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
  rm "go$ver.linux-amd64.tar.gz"
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
  source ~/.bash_profile


  download_default
}

move_to_new_network() {
  all_data_story="$HOME/.story/story/config/priv_validator_key.json"
  backup_file="$HOME/backup_file_story.txt"
  cat "$all_data_story" > "$backup_file"

  cd $HOME
  cat backup_file_story.txt
  read -p "ВАЖНО: Сохраните все данные, которые вывелись у вас на экране (введите любую кнопку чтобы продолжить): " checkjust

  sudo rm -r $HOME/.story


  download_default
}

download_default() {
  cd $HOME
  wget https://github.com/piplabs/story-geth/releases/download/v0.10.0/geth-linux-amd64
  [ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
  if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
    echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  fi
  chmod +x geth-linux-amd64
  mv $HOME/geth-linux-amd64 $HOME/go/bin/story-geth
  source $HOME/.bash_profile

  cd $HOME
  wget https://github.com/piplabs/story/releases/download/v0.12.0/story-linux-amd64
  [ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
  if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
    echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  fi
  chmod +x story-linux-amd64
  mv $HOME/story-linux-amd64 $HOME/go/bin/story
  source $HOME/.bash_profile

  read -p "Придумайте имя вашей ноде: " node_name
  story init --network odyssey --moniker "$node_name"

  sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story-geth --odyssey --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

  sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story run
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload && \
  sudo systemctl start story-geth && \
  sudo systemctl enable story-geth

  sudo systemctl daemon-reload && \
  sudo systemctl start story && \
  sudo systemctl enable story

  PEERS=$(curl -sS https://story-cosmos-rpc.spidernode.net/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}' | paste -sd, -)
  sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.story/story/config/config.toml

  sudo systemctl restart story
  sudo systemctl restart story-geth
}

check_sync() {
  echo 'Для того, чтобы долго не ждать - переходите к пункту SNAPSHOT'

  rpc_port=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/.story/story/config/config.toml" | cut -d ':' -f 3)
  while true; do
    local_height=$(curl -s localhost:$rpc_port/status | jq -r '.result.sync_info.latest_block_height')
    network_height=$(curl -s https://story-testnet-rpc.itrocket.net/status | jq -r '.result.sync_info.latest_block_height')

    if ! [[ "$local_height" =~ ^[0-9]+$ ]] || ! [[ "$network_height" =~ ^[0-9]+$ ]]; then
      echo -e "\033[1;31mОшибка при проверке данных. Повтор...\033[0m"
      sleep 5
      continue
    fi

    blocks_left=$((network_height - local_height))
    if [ "$blocks_left" -lt 0 ]; then
      blocks_left=0
    fi

    echo -e "\033[1;36mБлоков до синхронизации:\033[1;32m $blocks_left\033[0m"

    sleep 5
  done
}

download_snapshot() {
  sudo apt-get install wget lz4 aria2 pv -y

  sudo systemctl stop story
  sudo systemctl stop story-geth

  cd $HOME
  aria2c -x 16 -s 16 https://snapshot.spidernode.net/Geth_snapshot.lz4

  cd $HOME
  aria2c -x 16 -s 16 https://snapshot.spidernode.net/Story_snapshot.lz4

  mv $HOME/.story/story/data/priv_validator_state.json $HOME/.story/priv_validator_state.json.backup

  rm -rf ~/.story/story/data
  rm -rf ~/.story/geth/odyssey/geth/chaindata

  sudo mkdir -p /root/.story/story/data
  lz4 -d Story_snapshot.lz4 | pv | sudo tar xv -C /root/.story/story/

  sudo mkdir -p /root/.story/geth/odyssey/geth/chaindata
  lz4 -d Geth_snapshot.lz4 | pv | sudo tar xv -C /root/.story/geth/odyssey/geth/

  mv $HOME/.story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

  sudo systemctl start story
  sudo systemctl start story-geth

  sudo rm -rf Story_snapshot.lz4
  sudo rm -rf Geth_snapshot.lz4
}

restore_validators_data() {
  if [ -f "$HOME/backup_file_story.txt" ]; then
    cat "$HOME/backup_file_story.txt" > "$HOME/.story/story/config/priv_validator_key.json"

    cd $HOME
    sudo rm backup_file_story.txt
  else
    sudo nano /$HOME/.story/story/config/priv_validator_key.json
  fi

  echo 'Восстановились...'
}

export_wallet() {
  echo 'Сохраните все данные в надежном месте...'

  story validator export

  story validator export --export-evm-key

  sleep 1

  cat /$HOME/.story/story/config/private_key.txt
}

create_validator() {
  story validator create --stake 1000000000000000000 --private-key $(cat $HOME/.story/story/config/private_key.txt | grep "PRIVATE_KEY" | awk -F'=' '{print $2}')
}

check_logs_story() {
  sudo journalctl -u story -f
}

check_logs_story_geth() {
  sudo journalctl -u story-geth -f
}

delete_node() {
  sudo systemctl stop story story-geth
  sudo systemctl disable story story-geth
  rm -rf $HOME/.story
  sudo rm /etc/systemd/system/story.service /etc/systemd/system/story-geth.service
  sudo systemctl daemon-reload
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🛠️ Установить ноду"
    echo "2. 🔄 Проверить синхронизацию"
    echo "3. 📦 Установить SNAPSHOT"
    echo "4. 🌌 Перейти на новую сеть (Odyssey)"
    echo "5. 🗄️ Восстановить данные"
    echo "6. 💼 Экспорт кошелька"
    echo "7. 📜 Посмотреть логи STORY"
    echo "8. 📜 Посмотреть логи STORY-GETH"
    echo "9. 🗑️ Удалить ноду"
    echo -e "10. ❌ Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_sync
        ;;
      3)
        download_snapshot
        ;;
      4)
        move_to_new_network
        ;;
      5)
        restore_validators_data
        ;;
      6)
        export_wallet
        ;;
      7)
        check_logs_story
        ;;
      8)
        check_logs_story_geth
        ;;
      9)
        delete_node
        ;;
      10)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
