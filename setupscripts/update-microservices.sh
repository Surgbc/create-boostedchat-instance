#!/bin/bash

update_service_name="updatedboostedchatmses"
## if an argument is supplied run the below

# Check 2 arguments supplied
if [ $# -eq 2 ]; then

    cat <<EOF > "/etc/systemd/system/$update_service_name.service"
[Unit]
Description=Update boostedchat service
After=network.target

[Service]
Type=simple
WorkingDirectory=/tmp
Environment="HOME=/root"
ExecStart=/tmp/update-microservices.sh $2
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to read the newly added unit files
        sudo systemctl daemon-reload

        # Start and enable the service
        sudo systemctl start $update_service_name
        sudo systemctl enable $update_service_name

        # Check service status
        sudo systemctl status $update_service_name

exit 0
fi


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
echo $2
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
        # exit 1
        ;;
esac

function remove_service() {
    # Stop and disable the service
    # sudo systemctl stop $update_service_name
    sudo systemctl disable $update_service_name

    # Remove the service file
    sudo rm "/etc/systemd/system/$update_service_name.service"

    # Reload systemd
    sudo systemctl daemon-reload

    # Check service status (optional)
    systemctl status $update_service_name
    rm /tmp/update-microservices.sh
    sudo systemctl stop $update_service_name
}

echo "removing service"
# Remove microservice if no argument is supplied
remove_service
# this will not run since the service will be stopped in the previous step
echo "end of script"