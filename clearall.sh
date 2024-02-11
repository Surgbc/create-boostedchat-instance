#!/bin/bash

sudo systemctl stop installboostedchat
sudo systemctl disable installboostedchat
sudo rm /etc/systemd/system/installboostedchat.service
sudo systemctl daemon-reload

rm -rf boostedchat-site

docker stop $(docker ps -q)
docker rmi -f $(docker images -aq)
./setupvm.sh dev

journalctl -f -u installboostedchat