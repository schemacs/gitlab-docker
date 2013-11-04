#!/bin/bash

# start SSH
/usr/sbin/sshd

# start redis
redis-server > /dev/null 2>&1 &
sleep 5

# Run the firstrun script
/srv/gitlab/firstrun.sh

# remove PIDs created by GitLab init script
rm /home/git/gitlab/tmp/pids/*

# start gitlab
service gitlab start

# keep script in foreground
tail -f /home/git/gitlab/log/production.log
