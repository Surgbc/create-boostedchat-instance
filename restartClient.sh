#!/bin/bash

sudo docker compose stop client
sudo docker compose rm client
name_of_the_image=$(sudo docker compose ps --format '{{.Names}} {{.Service}}' | grep 'client' | awk '{printf "%s", $1}')
name_of_the_image="lunyamwimages/boostedchatui:booksyus"
# sudo docker rmi $name_of_the_image
sudo docker rmi lunyamwimages/boostedchatui:booksyus

if [[ $(sudo docker compose ps -a | grep "certbot" | awk '{print $1}') ]]; then
        sudo docker compose stop certbot
        sudo docker compose rm certbot
fi

sudo docker volume rm boostedchat-site_web-root # it will most likely end in _web_root

#sudo docker compose pull client
sudo docker compose up -d client --no-deps --force-recreate