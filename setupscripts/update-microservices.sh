#!/bin/bash

# update and restart services


function client() {
    imageId=$(docker compose images client | awk 'NR>1 {print $4}')
    docker compose stop client
    docker compose rm -f client
    docker rmi $imageId
    docker volume rm $(docker volume ls --format "{{.Name}}" | grep "_web-root")
    docker compose up -d --build client
}


function api() {
    docker compose stop api
    docker compose pull api
    docker compose up -d --build api
    client # restart client also which has nginx
}

function mqtt() {
    docker compose stop mqtt
    docker compose pull mqtt
    docker compose up -d --build mqtt
}

function prompt() {
    docker compose stop prompt
    docker compose pull prompt
    docker compose up -d --build prompt
    client # restart client also which has nginx
}

function airflow-web() {
    docker compose -f docker-compose.airflow.yaml stop web
    docker compose -f docker-compose.airflow.yaml pull prompt
    docker compose -f docker-compose.airflow.yaml up -d --build prompt
    client # restart client also which has nginx
}

# Check if argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <function_name>"
    exit 1
fi

cd /root/boostedchat-site
echo $1
# Run function based on argument
case $1 in
    "client")
        client
        ;;
    "api")
        api
        ;;
    "mqtt")
        mqtt
        ;;
    "prompt")
        prompt
        ;;
    "airflow-web")
        airflow-web
        ;;
    *)
        echo "Invalid function name: $1"
        echo "Available functions: function1, function2"
        exit 1
        ;;
esac

exit 0
