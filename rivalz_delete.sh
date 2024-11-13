sudo npm uninstall -g rivalz-node-cli

cd $HOME

sudo rm -r .rivalz/

ps aux | grep rivalz | awk '{print $2}' | xargs -I {} sudo kill -9 {}

echo 'Все удалилось. Теперь перезагрузите ваш сервер.'
