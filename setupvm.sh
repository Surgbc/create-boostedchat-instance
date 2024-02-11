#/bin/bash

# Check if DEV_ENV environment variable is set
if [ "$DEV_ENV" == "true" ]; then
    BRANCH="dev"
else
    BRANCH="main"
fi


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
GIT_SSH_COMMAND='ssh -i /root/.ssh/id_rsa_git -o StrictHostKeyChecking=no' git -b $BRANCH clone git@github.com:LUNYAMWIDEVS/boostedchat-site.git

hostname=$(sed 's/\n//g' /etc/hostname) # assume hostname to be the new username

cd boostedchat-site

## nginx-config files
cp -r ./nginx-conf ./nginx-conf.1
rm -rf ./nginx-conf
mkdir ./nginx-conf
# cp ./nginx-conf/nginx.conf ./nginx-conf/nginx.ssl.conf 
# cp ./nginx-conf/nginx.nossl.conf ./nginx-conf/nginx.conf
cp ./nginx-conf.1/nginx.nossl.conf ./nginx-conf/nginx.conf

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