#!/bin/bash

sections=("$branch" "airflow-$branch")
# branch="dev"
echo "Branch:$branch"
echo  '{"include": [' > config.json


services=$(cat images.yaml | yq eval ".build.$branch | keys | .[]")

for section in "${sections[@]}"; do
    services=$(cat images.yaml | yq eval ".build.$section | keys | .[]")

    for service in $services; do
        whole_value=$(yq eval ".build.$section.$service" images.yaml)
        image_name=$(yq eval ".build.$section.$service | keys | .[]" "images.yaml")
        # Get the repository for the current service
        repository=$(yq eval ".build.$section.$service" images.yaml)

        # Extract the repository name from the value
        repository=$(echo "$repository" | cut -d':' -f2)
        echo $whole_value
        # repository=$(echo "$whole_value" | yq eval ". | split(":")[0]' -)
        repository=$(echo "$whole_value" |  sed "s|$image_name||" | sed 's/"//g' | sed 's/://g'| sed 's/^ //g' | sed 's/ [ ]*/ /g')
        part1=$(echo "$repository" | cut -d' ' -f1)  # LUNYAMWIDEVS/boostedchat.git
        part2=$(echo "$repository" | cut -d' ' -f2)  # dev
        repository=$part1
        if [ -n "$part2" ]; then
            innerBranch="$part2"
        else
            innerBranch="main"
        fi

        echo "Service: $service"
        echo "Image name: $image_name"
        echo "Repository: $repository"
        echo "Branch: $innerBranch"
        echo "----------------------"
        useService="$(echo $section | grep -o "^airflow\-" )$service"
        
        echo "{\"service\":\"$useService\", \"image\":\"$image_name\", \"repo\":\"$repository\", \"branch\":\"$innerBranch\"  }">> config.json
        echo "," >> config.json
    done
done

awk 'NR>1 {print prev} {prev=$0} END {print "]}" }' config.json > temp && mv temp config.json # replace last ,
