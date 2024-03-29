#!/bin/bash


### remove all docker
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker images -aq)
docker volume rm $(docker volume ls -q)

rm -rf boostedchat-site

sudo systemctl stop installboostedchat
sudo systemctl disable installboostedchat
sudo rm /etc/systemd/system/installboostedchat.service
sudo systemctl daemon-reload

rm -rf /opt/postgres-data
rm -rf /opt/postgres-etl-data
rm -rf /opt/postgres-etl-data