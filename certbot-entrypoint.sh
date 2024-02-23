#!/bin/sh

# Run Certbot commands for each subdomain
certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email tomek@boostedchat.com --agree-tos --no-eff-email --force-renewal -d jamel.boostedchat.com
certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email tomek@boostedchat.com --agree-tos --no-eff-email --force-renewal -d api.jamel.boostedchat.com
certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email tomek@boostedchat.com --agree-tos --no-eff-email --force-renewal -d airflow.jamel.boostedchat.com
certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email tomek@boostedchat.com --agree-tos --no-eff-email --force-renewal -d scrapper.jamel.boostedchat.com
certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email tomek@boostedchat.com --agree-tos --no-eff-email --force-renewal -d promptemplate.jamel.boostedchat.com

