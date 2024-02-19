#!/bin/sh

# install docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

usermod -aG docker ubuntu

# increase inotify limits
cat <<EOF >> /etc/sysctl.conf
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=524288
EOF

sudo sysctl -p

# run HTTP proxy on port 3128
docker run --rm -d -p "3128:3128/tcp" -p "1080:1080/tcp" ghcr.io/tarampampam/3proxy:latest

# finish setup
touch /setup-complete