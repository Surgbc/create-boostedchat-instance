# Notes

## Get IP address of docker container
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 80ec644107f4

psql -h boostedchat-dev.boostedchat.com -U postgres -d -p 5432 

psql -h boostedchat-dev.boostedchat.com -U postgres -d boostedchat-dev -p 5432


docker compose exec -it postgres psql -U postgres -d boostedchat-dev

ALTER USER postgres WITH PASSWORD 'Pu1Es02sRbk';