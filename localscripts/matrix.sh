#!/bin/bash

sections=("$branch" "airflow-$branch")
fullRepo=$1
# branch="dev"
echo "Branch:$branch"
echo  '{"include": [' > config.json

images_file="configs/images.yaml"
services=$(cat "$images_file" | yq eval ".build.$branch | keys | .[]")

for section in "${sections[@]}"; do
    services=$(cat "$images_file" | yq eval ".build.$section | keys | .[]")

    for service in $services; do
        whole_value=$(yq eval ".build.$section.$service" "$images_file")
        image_name=$(yq eval ".build.$section.$service | keys | .[]" "$images_file")
        # Get the repository for the current service
        repository=$(yq eval ".build.$section.$service" "$images_file")

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

        repoFull="fullRepo"
        # curl -s -H "Authorization: Bearer $PAT"  -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$repoFull/branches/devs$useService-$innerBranch
        
        response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $PAT" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$repoFull/branches/devs$useService-$innerBranch")
        if [ $response -eq 200 ]; then
            # Branch exists, proceed with adding data to config.json
            echo "{\"service\":\"$useService\", \"image\":\"$image_name\", \"repo\":\"$repository\", \"branch\":\"$innerBranch\"  }" >> config.json
        else
            # Branch does not exist, skipping
            echo "Branch devs$useService-$innerBranch does not exist. Skipping..."
        fi

        echo "{\"service\":\"$useService\", \"image\":\"$image_name\", \"repo\":\"$repository\", \"branch\":\"$innerBranch\"  }">> config.json
        echo "," >> config.json
    done
done

# awk 'NR>1 {print prev} {prev=$0} END {print "]}" }' config.json > temp && mv temp config.json # replace last ,
awk 'NR>1 {print prev} {prev=$0} END {sub(/,$/, "", prev); print prev "]}" }' config.json > temp && mv temp config.json  # replace last ,
