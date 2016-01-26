#!/bin/bash
ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
ID=${ID:2}
hostname $ID
