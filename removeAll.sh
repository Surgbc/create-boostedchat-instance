#!/bin/bash


### remove all docker
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker images -aq)
docker volume rm $(docker volume ls -q)

rm -rf boostedchat-site