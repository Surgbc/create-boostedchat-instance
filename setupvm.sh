#!/bin/bash

## globals
service_name="installboostedchat"
my_ip=$(curl -s ifconfig.me) #dig +short myip.opendns.com @resolver1.opendns.com # wget -qO- ipinfo.io/ip
hostname=$(sed 's/\n//g' /etc/hostname) # assume hostname to be the new username

isValidIp() {
    local ip="$1"
    local ip_pattern="^([0-9]{1,3}\.){3}[0-9]{1,3}$"  # IPv4 pattern

    if [[ "$ip" =~ $ip_pattern ]]; then
        return 0  # Valid IP address
    else
        return 1  # Invalid IP address
    fi
}

getMyIP() {
    my_ip=$(curl -s ifconfig.me)
    if ! isValidIp "$my_ip"; then 
        my_ip=$(dig +short myip.opendns.com @resolver1.opendns.com) 
        if ! isValidIp "$my_ip"; then 
            my_ip=$(wget -qO- ipinfo.io/ip) 
            if ! isValidIp "$my_ip"; then
                echo "Failed to retrieve the IP address." >&2
                exit 1
            fi
        fi
    fi
    echo "$my_ip"
}


env_var=$1
# Check if DEV_ENV environment variable is set
if [ "$env_var" == "dev" ]; then
    BRANCH="dev"
else
    BRANCH="main"
fi

echo "env=${env_var}"

## Check if the service already exists
serviceExists() {
    local service_file="/etc/systemd/system/$service_name.service"

    if [ -f "$service_file" ]; then
        return 0  # Service file exists
    else
        return 1  # Service file does not exist
    fi
}

createService() {
    local current_dir=$(pwd)
    local script_name=$(basename "$0")
    local service_file="/etc/systemd/system/$service_name.service"

    # Create the service unit file
    cat <<EOF > "/etc/systemd/system/$service_name.service"
[Unit]
Description=Setup Service
After=network.target

[Service]
Type=simple
WorkingDirectory=$current_dir/
Environment="HOME=/root"
ExecStart=$current_dir/$script_name $env_var
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
    sudo systemctl start $service_name
    sudo systemctl enable $service_name

    # Check service status
    sudo systemctl status $service_name
}


initialSetup() {
    sudo apt update
    sudo apt install docker.io -y

    # install docker compose plugins
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

    sudo apt install git -y


    ssh-keyscan GitHub.com > /root/.ssh/known_hosts #2>&1 >/dev/null
    ssh-keyscan GitHub.com > ~/.ssh/known_hosts #2>&1 >/dev/null
    chmod 644 ~/.ssh/known_hosts
    chmod 600 ~/.ssh/id_rsa_git
    chmod 644 /root/.ssh/known_hosts
    chmod 600 /root/.ssh/id_rsa_git

    # git clone -o StrictHostKeyChecking=no git@github.com:LUNYAMWIDEVS/boostedchat-site.git
    GIT_SSH_COMMAND='ssh -i /root/.ssh/id_rsa_git -o StrictHostKeyChecking=no' git clone -b $BRANCH git@github.com:LUNYAMWIDEVS/boostedchat-site.git

    cd boostedchat-site

    ## nginx-config files
    cp -r ./nginx-conf ./nginx-conf.1
    rm -rf ./nginx-conf
    mkdir ./nginx-conf 
    # I think having both files in nginx-conf causes the error with the client container before ssl certificate is configured
    # cp ./nginx-conf/nginx.conf ./nginx-conf/nginx.ssl.conf 
    # cp ./nginx-conf/nginx.nossl.conf ./nginx-conf/nginx.conf
    cp ./nginx-conf.1/nginx.nossl.conf ./nginx-conf/nginx.conf
    #
    sed -i 's/$http_host/127.0.0.1/g' ./nginx-conf/nginx.conf

    sed -i "s/jamel/$hostname/g" ./nginx-conf/*

    ## set up env variables
    cp /etc/boostedchat/.env ./


    ## change db name in docker-compose.yaml
    sed -i "s/POSTGRES_DB: jamel/POSTGRES_DB: $hostname/g" docker-compose.yaml  # This is hardcoded

    ### change database name
    sed -i "s/^POSTGRES_DBNAME=.*/POSTGRES_DBNAME=\"$hostname\"/" .env
    echo >> .env.example
    # echo "HOSTNAME=$hostname" >> .env
    ## echo "DOMAIN1=$hostname" >> .env
    ## echo "DOMAIN2=$hostname" >> .env
    sed -i "s/^DOMAIN1=.*/DOMAIN1=\"$hostname\"/" .env
    sed -i "s/^DOMAIN2=.*/DOMAIN2=\"$hostname\"/" .env
    source <(sed 's/^/export /' .env )  # is this really necessary, or does docker export the variables in .env by itself?

    ## log in to docker 
    docker login --username $DOCKER_USERNAME --password $DOCKER_PASSWORD

    ## Start the services defined in the docker-compose.airflow.yaml file
    docker compose -f docker-compose.airflow.yaml up --build -d


    ## Edit postgres-etl port
    sed -i "s/^#port = 5432/port = 5433/" /opt/postgres-etl-data/postgresql.conf

    ### restart
    docker compose -f docker-compose.airflow.yaml restart postgresetl
    docker compose -f docker-compose.airflow.yaml up --build -d
    docker compose up --build -d

    ## Edit prompt-factory
    sed -i "s/^#port = 5432/port = 5434/" /opt/postgres-promptfactory-data/postgresql.conf

    docker compose restart postgres-promptfactory

    #cp ./nginx-conf/nginx.ssl.conf ./nginx-conf/nginx.conf

    docker compose up --build -d --force-recreate

    ## Check logs of containers that have exited
    docker ps -a --filter "status=exited" --filter "exited=1" --format "{{.ID}} {{.Image}}" | while read -r container_id image_name; do echo ""; echo ""; echo ""; echo ""; echo ""; echo ""; echo "Container ID: $container_id, Image Name: $image_name"; docker logs "$container_id"; done
}

projectCreated() {
    local project_dir="/root/boostedchat-site"
     if [ ! -d "$project_dir" ]; then
        return 1  
    else 
        return 0
    fi
}

subdomainSet() {
    my_ip=$(getMyIP)
    if [ $? -eq 0 ]; then
        echo "My IP address is: $my_ip"
    else
        echo "Failed to retrieve my IP address ($my_ip)."
        return 1
    fi
    local subdomain="$hostname.boostedchat.com"
    local resolved_ip=$(dig +short "$subdomain")

    if [ "$resolved_ip" == "$my_ip" ]; then
        echo "The subdomain $subdomain points to the expected IP address: $my_ip"
        return 0  # Success
    else
        echo "The subdomain $subdomain does not point to the expected IP address ($my_ip). Resolved IP: $resolved_ip"
        return 1  # Failure
    fi
}

stopAndRemoveService() {
    sudo systemctl stop $service_name
    sudo systemctl disable $service_name
    sudo rm /etc/systemd/system/$service_name.service
    sudo systemctl daemon-reload
}

runCertbot() {
    cd /root/boostedchat-site
    cp ./nnginx-conf.1/nginx.ssl.conf ./nginx-conf/nginx.conf
    docker compose restart docker
    docker compose up --build -d --force-recreate
}

if ! serviceExists; then
    createService
else 
    if ! projectCreated; then
        initialSetup
    else
        if subdomainSet; then
            runCertbot
            stopAndRemoveService
        else
            while ! subdomainSet; do
                echo "Checking again in 60 seconds"
                sleep 60  # Wait for 60 seconds before checking again
            done
            runCertbot
            stopAndRemoveService
        fi
    fi
fi