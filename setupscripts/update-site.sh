#!/bin/bash

update_service_name="updatedboostedchatsite"
## if an argument is supplied run the below

# Check 2 arguments supplied
if [ $# -eq 2 ]; then

    cat <<EOF > "/etc/systemd/system/$update_service_name.service"
[Unit]
Description=Update boostedchat site
After=network.target

[Service]
Type=simple
WorkingDirectory=/tmp
Environment="HOME=/root"
ExecStart=/tmp/update-site.sh abc
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to read the newly added unit files
        sudo systemctl daemon-reload

        # Start and enable the service
        sudo systemctl start $update_service_name
        sudo systemctl enable $update_service_name

        # Check service status
        sudo systemctl status $update_service_name

exit 0
fi

which rsync || apt install rsync
# Change to the /root/boostedchat-site directory
cd /root/boostedchat-site

# SSH key scanning and permissions adjustment
ssh-keyscan GitHub.com > /root/.ssh/known_hosts 2>&1 >/dev/null
ssh-keyscan GitHub.com > ~/.ssh/known_hosts 2>&1 >/dev/null
chmod 644 ~/.ssh/known_hosts
chmod 600 ~/.ssh/id_rsa_git
chmod 644 /root/.ssh/known_hosts
chmod 600 /root/.ssh/id_rsa_git

# Git SSH command to pull updates from the remote repository
if command -v git &> /dev/null; then
    # Get the current branch using Git
    branch=$(git rev-parse --abbrev-ref HEAD)
    echo "Current branch: $branch"
    
    # bash /root/install.sh "$branch" copyDockerYamls
    # bash /root/install.sh "$branch" editNginxConf
    if [[ "$branch" == "dev" || "$branch" == "main" ]]; then
        # Pull the latest changes from the current branch using SSH (forcefully overwrite local changes)
        # git stash
        GIT_SSH_COMMAND='ssh -i /root/.ssh/id_rsa_git -o StrictHostKeyChecking=no' git pull -f origin "$branch"
        rsync -av nginx-conf/ nginx-conf.1/
        rm nginx-conf/nginx.nossl.conf
        # Copy install.sh from boostedchat-site to /root/install.sh
        cp install.sh /root/install.sh
        chmod +x /root/install.sh
    
        bash /root/install.sh "$branch" copyDockerYamls
        bash /root/install.sh "$branch" editNginxConf
    else
        echo "Skipping execution as the branch is not dev or main."
    fi
else
    echo "Git is not installed. Please install Git to use this script."
fi



function remove_service() {
    # Stop and disable the service
    # sudo systemctl stop $update_service_name
    

    # Remove the service file
    sudo rm "/etc/systemd/system/$update_service_name.service"
    sudo systemctl disable $update_service_name
    # Reload systemd
    sudo systemctl daemon-reload

    # Check service status (optional)
    systemctl status $update_service_name
    rm /tmp/update-site.sh
    sudo systemctl stop $update_service_name
}

echo "removing service"
# Remove microservice if no argument is supplied
remove_service
# this will not run since the service will be stopped in the previous step
echo "end of script"