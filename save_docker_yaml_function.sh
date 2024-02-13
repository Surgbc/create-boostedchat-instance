save_docker_yaml() {
    cat <<DOC_EOF > docker-compose.yaml
version: "3"

services:
  api:
    image: lunyamwimages/boostedchatapi:booksyus
    restart: always
    ports:
      - "8000:8000"
    volumes:
      - web-django:/usr/src/app
      - web-static:/usr/src/app/static
    env_file:
      - .env
    entrypoint: ["/bin/bash", "+x", "/entrypoint.sh"]
    networks:
      - booksy

  postgres:
    image: postgres:latest
    container_name: postgres-container
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: boostedchat
      POSTGRES_DB: ${DOMAIN2}
    volumes:
      - /opt/postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - booksy
  
  postgres-promptfactory:
    image: postgres:latest
    container_name: postgres-promptfactory-container
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: boostedchat
      POSTGRES_DB: promptfactory
    volumes:
      - /opt/postgres-promptfactory-data:/var/lib/postgresql/data
    ports:
      - "5434:5434"
    networks:
      - booksy

  client:
    image: lunyamwimages/boostedchatui:booksyus
    restart: always
    depends_on:
      - api
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - web-root:/usr/share/nginx/html
      - ./nginx-conf/:/etc/nginx/conf.d
      - certbot-etc:/etc/letsencrypt
      - certbot-var:/var/lib/letsencrypt
      - ./dhparam:/etc/ssl/certs
    networks:
      - booksy

  certbot:
    image: certbot/certbot
    container_name: certbot
    volumes:
      - certbot-etc:/etc/letsencrypt
      - certbot-var:/var/lib/letsencrypt
      - web-root:/usr/share/nginx/html
    depends_on:
      - client
    command: certonly --webroot --webroot-path=/usr/share/nginx/html --email tomek@boostedchat.com --agree-tos --no-eff-email --force-renewal -d ${DOMAIN2}.boostedchat.com -d api.${DOMAIN2}.boostedchat.com -d airflow.${DOMAIN2}.boostedchat.com -d scrapper.${DOMAIN2}.boostedchat.com -d promptemplate.${DOMAIN2}.boostedchat.com
    networks:
      - booksy

  mqtt:
    image: lunyamwimages/boostedchatmqtt
    restart: always
    ports:
      - "1883:1883"
      - "8883:8883"
      - "3000:3000"
    volumes:
      - ../mqtt-logs:/usr/src/app/logs
    env_file:
      - .env
    networks:
      - booksy

  prompt:
    image: lunyamwimages/promptfactory
    restart: always
    depends_on:
      - api
    ports:
      - "8001:8001"
    networks:
      - booksy
    env_file:
      - .env

  salesrep:
    image: lunyamwimages/boostedchatamqp
    env_file:
      - .env
    networks:
      - booksy

  message-broker:
    image: rabbitmq:3-management-alpine
    container_name: message-broker
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    volumes:
      - rabbitmq-data:/var/lib/rabbitmq/
      - rabbitmq-log:/var/log/rabbitmq
    restart: always
    networks:
      - booksy

volumes:
  web-django:
  web-static:
  certbot-etc:
  certbot-var:
  rabbitmq-data:
  rabbitmq-log:
  web-root:
  dhparam:

networks:
  booksy:
    external: true
    name: booksy-talk
DOC_EOF
    echo "Docker YAML content saved successfully."
}
