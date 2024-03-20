
#!/bin/bash

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

    # Pull the latest changes from the current branch using SSH (forcefully overwrite local changes)
        git stash
    GIT_SSH_COMMAND='ssh -i /root/.ssh/id_rsa_git -o StrictHostKeyChecking=no' git pull -f origin "$branch"
        rsync -av nginx-conf/ nginx-conf.1/
        rm nginx-conf/nginx.nossl.conf
    # Copy install.sh from boostedchat-site to /root/install.sh
    cp install.sh /root/install.sh
    chmod +x /root/install.sh
    bash /root/install.sh "$branch" copyDockerYamls
else
    echo "Git is not installed. Please install Git to use this script."
fi