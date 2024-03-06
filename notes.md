# Notes

## Get IP address of docker container
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 80ec644107f4

psql -h boostedchat-dev.boostedchat.com -U postgres -d -p 5432 