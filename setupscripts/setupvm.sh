#!/bin/bash

## globals
service_name="installboostedchat"
update_service_name="updateboostedchat"
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


copyDockerYamls() {
    if [ "$BRANCH" == "dev" ]; then
        save_docker_yaml
        save_docker_airflow_yaml
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


createUpdateService() {
    saveWatch #/root/watch.sh
    local current_dir=$(pwd)
    local script_name="watch.sh"
    local service_file="/etc/systemd/system/$update_service_name.service"

    sudo systemctl stop $service_name
    sudo systemctl disable $service_name
    if [ -f "/etc/systemd/system/$update_service_name.service" ]; then
        sudo rm /etc/systemd/system/$service_name.service
    fi
    # Create the service unit file
    cat <<EOF > "/etc/systemd/system/$update_service_name.service"
[Unit]
Description=Update boostedchat service
After=network.target

[Service]
Type=simple
WorkingDirectory=$current_dir/
Environment="HOME=/root"
ExecStart=$current_dir/$script_name
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
    sed -i "s/jamel/$hostname/g" ./nginx-conf.1/*

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

    # if [ "$BRANCH" == "dev" ]; then
    #     save_docker_yaml
    #     save_docker_airflow_yaml
    # fi
    copyDockerYamls

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
    if certificates_exist; then 
        return 0
    fi
    local subdomain_="$hostname"
    local domain="boostedchat.com"
    subdomains=(
        "${subdomain_}.${domain}"
        "airflow.${subdomain_}.${domain}"
        "api.${subdomain_}.${domain}"
        "promptemplate.${subdomain_}.${domain}"
        "scrapper.${subdomain_}.${domain}"
    )

    my_ip=$(getMyIP)
    if [ $? -eq 0 ]; then
        echo "My IP address is: $my_ip"
    else
        echo "Failed to retrieve my IP address ($my_ip)."
        return 1
    fi
    # local subdomain="$hostname.boostedchat.com"
    # local resolved_ip=$(dig +short "$subdomain")

    # if [ "$resolved_ip" == "$my_ip" ]; then
    #     echo "The subdomain $subdomain points to the expected IP address: $my_ip"
    #     return 0  # Success
    # else
    #     echo "The subdomain $subdomain does not point to the expected IP address ($my_ip). Resolved IP: $resolved_ip"
    #     return 1  # Failure
    # fi
    success_flag=0
    # Iterate over each subdomain and check its resolved IP address
    for subdomain in "${subdomains[@]}"; do
        resolved_ip=$(dig +short "$subdomain")
        if [ "$resolved_ip" == "$my_ip" ]; then
            echo "The subdomain $subdomain points to the expected IP address: $my_ip"
        else
            echo "The subdomain $subdomain does not point to the expected IP address ($my_ip). Resolved IP: $resolved_ip"
            return 1
        fi
    done
    return 0
}

stopAndRemoveService() {
    sudo systemctl stop $service_name
    sudo systemctl disable $service_name
    sudo rm /etc/systemd/system/$service_name.service
    sudo systemctl daemon-reload
}

certificates_exist() {
    local file_exists=false

    # Iterate through each container
    for container_id in $(docker ps -q); do
        # docker exec "$container_id" test -e "/etc/letsencrypt/live/$hostname.boostedchat.com/privkey.pem" && file_exists=true
        if docker exec "$container_id" test -e "/etc/letsencrypt/live/$hostname.boostedchat.com/privkey.pem"; then
            # Return true if the file exists in any container
            return 0
        fi
    done
    return 1
}

runCertbot() {
    cd /root/boostedchat-site
    saveCertbotEntry
    sed -i "s/jamel/$hostname/g" certbot-entrypoint.sh

    # if ! certificates_exist; then 
        # check if certificate already exist
        docker compose restart certbot
        echo "Waiting for certbot to run"
        sleep 60 
        docker logs certbot
        
        cp ./nginx-conf.1/nginx.conf ./nginx-conf/nginx.conf
        docker compose up --build -d --force-recreate
    # fi
    
}

## leave the lines that follow as is. It is used as a line_marker for a function which will be created here by copy_dev_docker_file.sh
## replace with docker function


## replace with docker airflow function

## replace with savepullUpdatedImages

## replace with saveWatch


## replace with certbotEntryPoint

if [ ! -f "/root/watch.sh" ]; then
    createUpdateService
fi

if [ ! -f "/root/pullUpdatedImages.sh" ]; then
    savePullUpdatedImages
fi

if ! serviceExists; then
    createService
else 
    copyDockerYamls             # just in case there are any updates
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