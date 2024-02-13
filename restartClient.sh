#!/bin/bash

sudo docker compose stop client
sudo docker compose rm --force client
name_of_the_image=$(docker inspect -f '{{ .Config.Image }}' boostedchat-site-client-1)
# name_of_the_image="lunyamwimages/boostedchatui:booksyus"
sudo docker rmi -$name_of_the_image

if [[ $(sudo docker compose ps -a | grep "certbot" | awk '{print $1}') ]]; then
        sudo docker compose stop certbot
        sudo docker compose rm certbot
fi

sudo docker volume rm boostedchat-site_web-root # it will most likely end in _web_root

#sudo docker compose pull client
# sudo docker compose up -d client  --force-recreate

docker compose up --build -d client  --force-recreate