#!/bin/bash

# branch="dev"
echo "Branch:$branch"
services=$(cat images.yaml | yq eval ".build.$branch | keys | .[]")

echo  '{"include": [' > config.json
for service in $services; do
    whole_value=$(yq eval ".build.$branch.$service" images.yaml)
    image_name=$(yq eval ".build.$branch.$service | keys | .[]" "images.yaml")
    # Get the repository for the current service
    repository=$(yq eval ".build.$branch.$service" images.yaml)


    # Extract the repository name from the value
    repository=$(echo "$repository" | cut -d':' -f2)
    echo $whole_value
    # repository=$(echo "$whole_value" | yq eval ". | split(":")[0]' -)
    repository=$(echo "$whole_value" |  sed "s|$image_name||" | sed 's/"//g' | sed 's/://g'| sed 's/^ //g' | sed 's/ [ ]*/ /g')
    part1=$(echo "$repository" | cut -d' ' -f1)  # LUNYAMWIDEVS/boostedchat.git
    part2=$(echo "$repository" | cut -d' ' -f2)  # dev
    repository=$part1
    if [ -n "$part2" ]; then
        branch="$part2"
    else
        branch="main"
    fi

    echo "Service: $service"
    echo "Image name: $image_name"
    echo "Repository: $repository"
    echo "Branch: $branch"
    echo "----------------------"
    echo "{\"service\":\"$service\", \"image\":\"$image_name\", \"repo\":\"$repository\", \"branch\":\"$branch\"  }">> config.json
    echo "," >> config.json
done
awk 'NR>1 {print prev} {prev=$0} END {print "]}" }' config.json > temp && mv temp config.json # replace last ,
cat config.json
