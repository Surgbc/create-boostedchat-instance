#!/bin/sh

# Run Certbot commands for each subdomain
[ -f /etc/letsencrypt/live/jamel.boostedchat.com/privkey.pem ] || certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email tomek@boostedchat.com --agree-tos --no-eff-email --force-renewal -d jamel.boostedchat.com
[ -f /etc/letsencrypt/live/api.jamel.boostedchat.com/privkey.pem ] || certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email tomek@boostedchat.com --agree-tos --no-eff-email --force-renewal -d api.jamel.boostedchat.com
[ -f /etc/letsencrypt/live/airflow.jamel.boostedchat.com/privkey.pem ] || certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email tomek@boostedchat.com --agree-tos --no-eff-email --force-renewal -d airflow.jamel.boostedchat.com
[ -f /etc/letsencrypt/live/scrapper.jamel.boostedchat.com/privkey.pem ] || certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email tomek@boostedchat.com --agree-tos --no-eff-email --force-renewal -d scrapper.jamel.boostedchat.com
[ -f /etc/letsencrypt/live/promptemplate.jamel.boostedchat.com/privkey.pem ] || certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email tomek@boostedchat.com --agree-tos --no-eff-email --force-renewal -d promptemplate.jamel.boostedchat.com

echo "done..."
## comments