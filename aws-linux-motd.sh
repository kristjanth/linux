#!/bin/bash
ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
ID=${ID:2}
LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

cat > /etc/motd <<EOF
--------------------------------------------------------------------------------
$ZONE
$ID
$PUBLIC_IP
$LOCAL_IP
--------------------------------------------------------------------------------
EOF
