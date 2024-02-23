#!/bin/bash

# copy some files from this repo to install.sh so as to push to -site repo in workflow 

copy_docker_yaml_and_create_function() {
    # Check if docker.yaml file exists
    if [ -f "docker-compose.yaml" ]; then
        # Create a function to save the contents of docker.yaml
        cat <<EOF > save_docker_yaml_function.sh
save_docker_yaml() {
    cat <<'DOC_EOF' > /root/boostedchat-site/docker-compose.yaml
$(<docker-compose.yaml)
DOC_EOF
    echo "Docker YAML content saved successfully."
}
EOF

    else
        echo "Error: docker.yaml file not found."
    fi

    if [ -f "docker-compose.airflow.yaml" ]; then
        # Create a function to save the contents of docker.yaml
        cat <<EOF > save_docker_airflow_yaml_function.sh
save_docker_airflow_yaml() {
    cat <<'DOC_EOF' > /root/boostedchat-site/docker-compose.airflow.yaml
$(<docker-compose.airflow.yaml)
DOC_EOF
    echo "Docker YAML content saved successfully."
}
EOF

    else
        echo "Error: docker-compose.airflow.yamlfile not found."
    fi

    if [ -f "pullUpdatedImages.sh" ]; then
        # Create a function to save the contents of docker.yaml
        cat <<EOF > savepullUpdatedImages.sh
savePullUpdatedImages() {
    cat <<'DOC_EOF' > /root/pullUpdatedImages.sh
$(<pullUpdatedImages.sh)
DOC_EOF
    chmod +x /root/pullUpdatedImages.sh
    echo "pullUpdatedImages.sh content saved successfully."
}
EOF

    else
        echo "Error: pullUpdatedImages.sh file not found."
    fi
    
    if [ -f "watch.sh" ]; then
        # Create a function to save the contents of docker.yaml
        cat <<EOF > saveWatch.sh
saveWatch() {
    cat <<'DOC_EOF' > /root/watch.sh
$(<watch.sh)
DOC_EOF
    chmod +x /root/watch.sh
    echo "watch.sh content saved successfully."
}
EOF

    else
        echo "Error: watch.sh file not found."
    fi

    if [ -f "certbot-entrypoint.sh" ]; then
        # Create a function to save the contents of docker.yaml
        cat <<EOF > saveCertbot-entrypoint.sh
saveCertbotEntry() {
    cat <<'DOC_EOF' > /root/boostedchat-site/certbot-entrypoint.sh
$(<certbot-entrypoint.sh)
DOC_EOF
    chmod +x certbot-entrypoint.sh
    echo "certbot-entrypoint.sh content saved successfully."
}
EOF

    else
        echo "Error: certbot-entrypoint.sh file not found."
    fi
}

    

copy_docker_yaml_and_create_function

## docker-compose.yaml
# add to setupvm.sh
replacement_file="save_docker_yaml_function.sh"
line_marker="## replace with docker function"
# Perform the replacement
sed -i "/$line_marker/{r $replacement_file
        d}" setupvm.sh
rm $replacement_file

## docker-compose.airflow.yaml
replacement_file="save_docker_airflow_yaml_function.sh"
line_marker="## replace with docker airflow function"
# Perform the replacement
sed -i "/$line_marker/{r $replacement_file
        d}" setupvm.sh
rm $replacement_file



# add to setupvm.sh
replacement_file="savepullUpdatedImages.sh"
line_marker="## replace with savepullUpdatedImages"

# Perform the replacement
sed -i "/$line_marker/{r $replacement_file
        d}" setupvm.sh
rm $replacement_file


# add to setupvm.sh
replacement_file="saveWatch.sh"
line_marker="## replace with saveWatch"

# Perform the replacement
sed -i "/$line_marker/{r $replacement_file
        d}" setupvm.sh
rm $replacement_file


### certbot entry point
replacement_file="saveCertbot-entrypoint.sh"
line_marker="## replace with certbotEntryPoint"

# Perform the replacement
sed -i "/$line_marker/{r $replacement_file
        d}" setupvm.sh
rm $replacement_file