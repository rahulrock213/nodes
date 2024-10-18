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
  VER="1.23.1"
  wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
  rm "go$VER.linux-amd64.tar.gz"
  [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
  echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  source $HOME/.bash_profile
  [ ! -d ~/go/bin ] && mkdir -p ~/go/bin

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

  SEEDS="51ff395354c13fab493a03268249a74860b5f9cc@story-testnet-seed.itrocket.net:26656"
  PEERS="2f372238bf86835e8ad68c0db12351833c40e8ad@story-testnet-peer.itrocket.net:26656,343507f6105c8ebced67765e6d5bf54bc2117371@38.242.234.33:26656,de6a4d04aab4e22abea41d3a4cf03f3261422da7@65.109.26.242:25556,7844c54e061b42b9ed629b82f800f2a0055b806d@37.27.131.251:26656,1d3a0e76b5cdf550e8a0351c9c8cd9b5285be8a2@77.237.241.33:26656,f1ec81f4963e78d06cf54f103cb6ca75e19ea831@217.76.159.104:26656,2027b0adffea21f09d28effa3c09403979b77572@198.178.224.25:26656,118f21ef834f02ab91e3fc3e537110efb4c1c0ac@74.118.140.190:26656,8876a2351818d73c73d97dcf53333e6b7a58c114@3.225.157.207:26656,caf88cbcd0628188999104f5ea6a5eed4a34422c@178.63.184.134:26656,7f72d44f3d448fd44485676795b5cb3b62bf5af0@142.132.135.125:20656"
  sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
         -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.story/story/config/config.toml

  wget -O $HOME/.story/story/config/genesis.json https://server-3.itrocket.net/testnet/story/genesis.json
  wget -O $HOME/.story/story/config/addrbook.json  https://server-3.itrocket.net/testnet/story/addrbook.json

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

  if [[ "$snapshot_first_link" =~ ^curl ]]; then
    if grep -q 'https' <<< "$snapshot_first_link"; then
      echo "$snapshot_first_link"
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

  if [[ "$snapshot_second_link" =~ ^curl ]]; then
    if grep -q 'https' <<< "$snapshot_second_link"; then
      echo "$snapshot_second_link"
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
  cat /root/.story/story/config/private_key.txt

  story validator export --export-evm-key
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
