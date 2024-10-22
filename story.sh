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

  sudo apt-get update -y && sudo apt upgrade -y && sudo apt-get install make build-essential nano screen unzip lz4 gcc git jq -y

  screen -S storynode
}

keep_download() {
  cd $HOME
  sudo rm -rf /usr/local/go
  curl -Ls https://go.dev/dl/go1.23.1.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
  eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
  eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

  read -p "Придумайте имя вашей ноде: " node_name
  echo "export MONIKER=\"$node_name\"" >> $HOME/.bash_profile
  echo "export STORY_CHAIN_ID="iliad-0"" >> $HOME/.bash_profile
  echo "export STORY_PORT="52"" >> $HOME/.bash_profile
  source $HOME/.bash_profile

  cd $HOME
  rm -rf bin
  mkdir bin
  cd bin
  wget -O geth https://github.com/piplabs/story-geth/releases/download/v0.9.4/geth-linux-amd64
  chmod +x geth
  mv ~/bin/geth ~/go/bin/
  mkdir -p ~/.story/story
  mkdir -p ~/.story/geth

  cd $HOME
  rm -rf story
  git clone https://github.com/piplabs/story
  cd story
  git checkout v0.11.0
  go build -o story ./client
  sudo mv ~/story/story ~/go/bin/

  story init --moniker "$node_name" --network iliad

  SEEDS="b6fb541c80d968931602710342dedfe1f5c577e3@story-seed.mandragora.io:23656,51ff395354c13fab493a03268249a74860b5f9cc@story-testnet-seed.itrocket.net:26656,5d7507dbb0e04150f800297eaba39c5161c034fe@135.125.188.77:26656"
  PEERS="$(curl -sS https://story-rpc.mandragora.io/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}' | paste -sd, -)"
  sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
         -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.story/story/config/config.toml

  wget -O $HOME/.story/story/config/genesis.json https://storage.crouton.digital/testnet/story/files/genesis.json
  wget -O $HOME/.story/story/config/addrbook.json https://story.snapshot.stake-take.com/addrbook.json

  sed -i.bak -e "s%:1317%:${STORY_PORT}317%g;
  s%:8551%:${STORY_PORT}551%g" $HOME/.story/story/config/story.toml
  sed -i.bak -e "s%:26658%:${STORY_PORT}658%g;
  s%:26657%:${STORY_PORT}657%g;
  s%:26656%:${STORY_PORT}656%g;
  s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${STORY_PORT}656\"%;
  s%:26660%:${STORY_PORT}660%g" $HOME/.story/story/config/config.toml
  sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.story/story/config/config.toml
  sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.story/story/config/config.toml

  sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which geth) --iliad --syncmode full --http --http.api eth,net,web3,engine --http.vhosts '*' --http.addr 0.0.0.0 --http.port ${STORY_PORT}545 --authrpc.port ${STORY_PORT}551 --ws --ws.api eth,web3,net,txpool --ws.addr 0.0.0.0 --ws.port ${STORY_PORT}546
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/.story/story
ExecStart=$(which story) run

Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

  cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup

  rm -rf $HOME/.story/story/data

  read -p "Скопируйте ПЕРВУЮ (!) актуальную ссылку на snapshot ноды по ссылке из гайда (curl https...): " snapshot_first_link

  curl_command=$(echo "$snapshot_first_link")

  if [[ "$snapshot_first_link" =~ ^curl ]]; then
    if grep -q 'https' <<< "$snapshot_first_link"; then
      eval "$curl_command"
    else
      echo "Неверный формат ссылки. Ссылка должна содержать 'https'"
    fi
  else
    echo "Неверный формат ссылки. Ссылка должна начинаться с 'curl'"
  fi
}

final_download() {
  mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json
  rm -rf $HOME/.story/geth/iliad/geth/chaindata
  mkdir -p $HOME/.story/geth/iliad/geth

  read -p "Скопируйте ВТОРУЮ (!!!) актуальную ссылку на snapshot ноды по ссылке из гайда (curl https...): " snapshot_second_link

  curl_command_second=$(echo "$snapshot_second_link")

  if [[ "$snapshot_second_link" =~ ^curl ]]; then
    if grep -q 'https' <<< "$snapshot_second_link"; then
      eval "$curl_command_second"
    else
      echo "Неверный формат ссылки. Ссылка должна содержать 'https'"
    fi
  else
    echo "Неверный формат ссылки. Ссылка должна начинаться с 'curl'"
  fi

  sudo systemctl daemon-reload
  sudo systemctl enable story story-geth
  sudo systemctl restart story story-geth
}

check_sync() {
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

export_wallet() {
  story validator export --export-evm-key

  sleep 1

  cat /root/.story/story/config/private_key.txt
}

create_validator() {
  story validator create --stake 1000000000000000000 --chain-id 1513 --private-key $(cat $HOME/.story/story/config/private_key.txt | grep "PRIVATE_KEY" | awk -F'=' '{print $2}')
}

check_logs() {
  sudo journalctl -u story -f
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. Установить библиотеки"
    echo "2. Установить ноду"
    echo "3. Продолжить установку"
    echo "4. Проверить синхронизацию"
    echo "5. Экспорт кошелька"
    echo "6. Создать валидатора"
    echo "7. Посмотреть логи"
    echo -e "8. Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        keep_download
        ;;
      3)
        final_download
        ;;
      4)
        check_sync
        ;;
      5)
        export_wallet
        ;;
      6)
        create_validator
        ;;
      7)
        check_logs
        ;;
      8)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
