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
    echo -e "2. Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice
    
    case $choice in
      1)
        ;;
	    2)
        exit 0
        ;;
      *)
        echo "Неверная пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
