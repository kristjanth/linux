#!/bin/bash
useradd -m "$1"
echo "$1:$2" | chpasswd
su - "$1" -c "echo $2 > ~/sudo-pass"
su - "$1" -c "mkdir ~/.ssh"
su - "$1" -c "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
su - "$1" -c "rm -f ~/.ssh/id_rsa*"
su - "$1" -c "echo $3 > ~/.ssh/authorized_keys"
su - "$1" -c "chmod 0600 ~/.ssh/authorized_keys"
