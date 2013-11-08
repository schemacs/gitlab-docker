#!/bin/bash -x

# start SSH
mkdir -p /var/run/sshd
/etc/init.d/ssh start

# start nginx
/etc/init.d/nginx start

# start postgresql
/etc/init.d/postgresql start

# start redis
/etc/init.d/redis-server start

# remove PIDs created by GitLab init script
rm -f /home/git/gitlab/tmp/pids/*

# start gitlab
service gitlab start

# display https certificate fingerprint
openssl x509 -noout -in /etc/nginx/crypto/cert.pem -fingerprint -sha1

# keep script in foreground
tail -f /home/git/gitlab/log/production.log
