#!/bin/bash
ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
hostname $ZONE"-"$ID
