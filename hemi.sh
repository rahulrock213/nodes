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

  sudo apt-get update -y && sudo apt upgrade -y
  sudo apt-get install make tar screen nano build-essential unzip lz4 gcc git jq -y

  sudo rm -rf /usr/local/go
  curl -Ls https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
  eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
  eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

  wget https://github.com/hemilabs/heminetwork/releases/download/v0.11.0/heminetwork_v0.11.0_linux_amd64.tar.gz
  mkdir -p hemi
  tar --strip-components=1 -xzvf heminetwork_v0.11.0_linux_amd64.tar.gz -C hemi
  sudo rm -rf heminetwork_v0.11.0_linux_amd64.tar.gz

  cd hemi/

  ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json

  eth_address=$(jq -r '.ethereum_address' ~/popm-address.json)
  private_key=$(jq -r '.private_key' ~/popm-address.json)
  public_key=$(jq -r '.public_key' ~/popm-address.json)
  pubkey_hash=$(jq -r '.pubkey_hash' ~/popm-address.json)

  echo "Дискорд канал, нужно зайти: https://discord.gg/hemixyz"
  echo "Запросите средства на этот адрес в канале faucet (в дискорде): $pubkey_hash"
  echo "Команда: /tbtc-faucet и вводите ваш адрес, который вывелся"
  read -p "Как выполните, введите любую кнопку сюда: " checkjust
  
  echo "export POPM_PRIVATE_KEY=$private_key" >> ~/.bashrc
  echo 'export POPM_STATIC_FEE=750' >> ~/.bashrc
  echo 'export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public' >> ~/.bashrc
  source ~/.bashrc

  sudo tee /etc/systemd/system/hemid.service > /dev/null <<EOF
[Unit]
Description=Hemi
After=network.target

[Service]
User=$USER
Environment="POPM_BFG_REQUEST_TIMEOUT=60s"
Environment="POPM_BTC_PRIVKEY=$private_key"
Environment="POPM_STATIC_FEE=750"
Environment="POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public"
WorkingDirectory=$HOME/hemi
ExecStart=$HOME/hemi/popmd
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl enable hemid
  sudo systemctl daemon-reload
  sudo systemctl start hemid
}

check_logs() {
  sudo journalctl -u hemid -f --no-hostname -o cat
}

output_all_data() {
  cd $HOME

  eth_address=$(jq -r '.ethereum_address' ~/popm-address.json)
  private_key=$(jq -r '.private_key' ~/popm-address.json)
  public_key=$(jq -r '.public_key' ~/popm-address.json)
  pubkey_hash=$(jq -r '.pubkey_hash' ~/popm-address.json)
  
  echo "Ethereum Address: $eth_address"
  echo "Private Key: $private_key"
  echo "Public Key: $public_key"
  echo "Pubkey Hash: $pubkey_hash"
}

change_fee() {
  service_file="/etc/systemd/system/hemid.service"
  
  read -p "Введите новое значение POPM_STATIC_FEE: " new_fee
  
  sudo sed -i "s/^Environment=\"POPM_STATIC_FEE=[0-9]*\"/Environment=\"POPM_STATIC_FEE=$new_fee\"/" "$service_file"
  
  sudo systemctl daemon-reload
  sudo systemctl restart hemid

  echo 'Значение FEE поменялось...'
}

auto_change() {
  cd $HOME

  sudo apt-get install screen jq pip -y
  pip install bs4 -y
  pip install requests -y

  python_script="fetch_pop_txs.py"

  service_file="/etc/systemd/system/hemid.service"
  
  prev_value_file="prev_pop_txs_value.txt"
  
  json_file="popm-address.json"
  
  public_key=$(jq -r '.public_key' "$json_file")
  
  cat <<EOF > "$python_script"
import requests
from bs4 import BeautifulSoup
import os

# URL of the page
public_key = os.getenv('PUBLIC_KEY')
url = f"https://testnet.popstats.hemi.network/pubkey/{public_key}.html"

# Make a request to fetch the page content
response = requests.get(url)

# Check for 404 status code
if response.status_code == 404:
    print("404")
else:
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Find all tables
    tables = soup.find_all('table')

    # Ensure there are at least 3 tables
    if len(tables) >= 3:
        third_table = tables[2]  # Select the third table
        rows = third_table.find_all('tr')
        pop_txs_value = rows[1].find_all('td')[0].text.strip()  # First cell in the second row
        print(f"{pop_txs_value}")
    else:
        print("Error: The third table was not found on the page.")
EOF
  
  update_fee() {
      current_fee=$(grep -oP 'POPM_STATIC_FEE=\K\d+' "$service_file")
      new_fee=$((current_fee + 500))
      sed -i "s/POPM_STATIC_FEE=$current_fee/POPM_STATIC_FEE=$new_fee/" "$service_file"
      echo "Updated POPM_STATIC_FEE to $new_fee"
  }
  
  while true; do
      if [ -f "$prev_value_file" ]; then
          prev_value=$(cat "$prev_value_file")
      else
          prev_value=""
      fi
  
      output=$(PUBLIC_KEY="$public_key" python3 "$python_script")
      
      if [ "$output" = "404" ]; then
          current_fee=$(grep -oP 'POPM_STATIC_FEE=\K\d+' "$service_file")
          if [ "$current_fee" -lt 1500 ]; then
              sed -i "s/POPM_STATIC_FEE=$current_fee/POPM_STATIC_FEE=1500/" "$service_file"
              sudo systemctl daemon-reload
              sudo systemctl restart hemid
              echo "Set POPM_STATIC_FEE to 1500 due to 404 error."
          else
              update_fee
          fi
      else
          current_value=$(echo "$output" | grep -o '[0-9]\+')
          if [ "$current_value" -eq "$prev_value" ]; then
              update_fee
          else
              echo "$current_value" > "$prev_value_file"
              echo "PoP Txs value has changed, no update to POPM_STATIC_FEE."
          fi
      fi
  
      # Sleep for 12 hours (43200 seconds)
      sleep 43200
  done
}

update_node() {
  sudo systemctl stop hemid.service
  sudo systemctl disable hemid.service
  sudo rm /etc/systemd/system/hemid.service
  sudo systemctl daemon-reload

  cd $HOME
  sudo rm -r hemi/

  sudo apt-get update -y && sudo apt upgrade -y

  wget https://github.com/hemilabs/heminetwork/releases/download/v0.11.0/heminetwork_v0.11.0_linux_amd64.tar.gz
  mkdir -p hemi
  tar --strip-components=1 -xzvf heminetwork_v0.11.0_linux_amd64.tar.gz -C hemi
  sudo rm -rf heminetwork_v0.11.0_linux_amd64.tar.gz

  cd hemi/

  eth_address=$(jq -r '.ethereum_address' ~/popm-address.json)
  private_key=$(jq -r '.private_key' ~/popm-address.json)
  public_key=$(jq -r '.public_key' ~/popm-address.json)
  pubkey_hash=$(jq -r '.pubkey_hash' ~/popm-address.json)

  sudo tee /etc/systemd/system/hemid.service > /dev/null <<EOF
[Unit]
Description=Hemi
After=network.target

[Service]
User=$USER
Environment="POPM_BFG_REQUEST_TIMEOUT=60s"
Environment="POPM_BTC_PRIVKEY=$private_key"
Environment="POPM_STATIC_FEE=750"
Environment="POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public"
WorkingDirectory=$HOME/hemi
ExecStart=$HOME/hemi/popmd
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl enable hemid
  sudo systemctl daemon-reload
  sudo systemctl start hemid
}

restart_node() {
  cd $HOME/hemi/

  sudo systemctl daemon-reload
  sudo systemctl restart hemid.service

  echo 'Перезагрузка была выполнена...'
}

delete_node() {
  read -p 'Если вы уверены удалить ноду, напишите любой символ (CTRL+C чтобы выйти): ' checkjust

  sudo systemctl stop hemid.service
  sudo systemctl disable hemid.service
  sudo rm /etc/systemd/system/hemid.service
  sudo systemctl daemon-reload

  cd $HOME
  sudo rm -r hemi/
  sudo rm popm-address.json
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🔧 Установить ноду"
    echo "2. 📜 Посмотреть логи"
    echo "3. 📊 Вывести данные"
    echo "4. 👨‍💻 Поменять значение POPM_STATIC_FEE"
    echo "5. 🚴‍♂️ Скрипт по авто-обновление POPM_STATIC_FEE (BETA)"
    echo "6. 🍪 Обновить ноду"
    echo "7. ♻️ Перезапустить ноду"
    echo "8. 🗑️ Удалить ноду"
    echo -e "9. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_logs
        ;;
      3)
        output_all_data
        ;;
      4)
        change_fee
        ;;
      5)
        auto_change
        ;;
      6)
        update_node
        ;;
      7)
        restart_node
        ;;
      8)
        delete_node
        ;;
      9)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
