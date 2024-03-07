# Notes

## Get IP address of docker container
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 80ec644107f4

psql -h boostedchat-dev.boostedchat.com -U postgres -d -p 5432 

psql -h devtest.boostedchat.com -U postgres -d devtest -p 5432
psql -h devtest.boostedchat.com -U postgres -d etl -p 5433
psql -h devtest.boostedchat.com -U postgres -d promptfactory -p 5434


docker compose exec -it postgres psql -U postgres -d boostedchat-dev

ALTER USER postgres WITH PASSWORD 'Pu1Es02sRbk';




### Create new server

```bash
curl -X POST \
  -H "Authorization: Bearer $token" \
  -H "Accept: application/vnd.github.everest-preview+json" \
  -H "Content-Type: application/json" \
  https://api.github.com/repos/LUNYAMWIDEVS/create-boostedchat-instance/dispatches \
  -d '{"event_type": "create-vm", "client_payload": {"branch": "dev", "vm_name": "testingdev", "password":"password1", "email":"abc@email.com"}}'
```