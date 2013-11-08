#!/bin/bash -x

# generate a new, random password for postgresql and set it here
POSTGRES_PASS=YOUR_RANDOM_PASSWORD

# set your fully qualified domain name here
DOMAIN_NAME=www.example.com


# === Do not modify anything in this section ===

# regenerate the ssh host key
rm /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

# copy over config files
cp /srv/gitlab/config/gitlab.yml   /home/git/gitlab/config/gitlab.yml
cp /srv/gitlab/config/database.yml /home/git/gitlab/config/database.yml
cp /srv/gitlab/config/nginx        /etc/nginx/sites-available/gitlab

# enable nginx host
ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab
rm /etc/nginx/sites-enabled/default

# set gitlab config owner and permissions
chown git:git /home/git/gitlab/config/database.yml /home/git/gitlab/config/gitlab.yml
chmod o-rwx /home/git/gitlab/config/database.yml /home/git/gitlab/config/gitlab.yml

# set postgres password
sed -i -e "s/PASSWORD/$POSTGRES_PASS/g" /home/git/gitlab/config/database.yml

# set domain name
sed -i -e "s/DOMAIN_NAME/$DOMAIN_NAME/g" /etc/nginx/sites-enabled/gitlab
sed -i -e "s/DOMAIN_NAME/$DOMAIN_NAME/g" /home/git/gitlab/config/gitlab.yml

# make unicorn listen on all interfaces
sed -i -e "s/127.0.0.1/0.0.0.0/g" /home/git/gitlab/config/unicorn.rb

# link data directories to /srv/gitlab/data
rm -R /home/git/gitlab/tmp
ln -s /srv/gitlab/data/tmp /home/git/gitlab/tmp
chown -R git /srv/gitlab/data/tmp/
chmod -R u+rwX  /srv/gitlab/data/tmp/

rm -R /home/git/.ssh
ln -s /srv/gitlab/data/ssh /home/git/.ssh
chown -R git:git /srv/gitlab/data/ssh
chmod -R 0700 /srv/gitlab/data/ssh
chmod 0700 /home/git/.ssh

# fix owner and permissions
chown -R git:git /srv/gitlab/data/gitlab-satellites
chown -R git:git /srv/gitlab/data/repositories
chmod -R ug+rwX,o-rwx /srv/gitlab/data/repositories
chmod -R ug-s /srv/gitlab/data/repositories/
find /srv/gitlab/data/repositories/ -type d -print0 | xargs -0 chmod g+s

# change repo path in gitlab-shell config
sed -i -e 's/\/home\/git\/repositories/\/srv\/gitlab\/data\/repositories/g' /home/git/gitlab-shell/config.yml

# postgres setup
sudo -u postgres postgres --single --config-file=/etc/postgresql/9.1/main/postgresql.conf <<< "CREATE USER gitlab WITH SUPERUSER;"
sudo -u postgres postgres --single --config-file=/etc/postgresql/9.1/main/postgresql.conf <<< "ALTER USER gitlab WITH PASSWORD '$POSTGRES_PASS';"
sudo -u postgres postgres --single --config-file=/etc/postgresql/9.1/main/postgresql.conf <<< "CREATE DATABASE gitlabhq_production OWNER gitlab"

# must be running for gitlab setup
/etc/init.d/postgresql start
/etc/init.d/redis-server start

# setup gitlab with rake
cd /home/git/gitlab
su git -c "bundle exec rake gitlab:setup force=yes RAILS_ENV=production"

# nginx cert and dh parameters
mkdir -p /etc/nginx/crypto
openssl req -x509 -newkey rsa:4096 -nodes -subj "/C=  /ST= /L= /O= /CN=$DOMAIN_NAME" -keyout /etc/nginx/crypto/cert.priv -out /etc/nginx/crypto/cert.pem -days 365
cp /srv/gitlab/config/dh-param-4096.pem /etc/nginx/crypto/dhparam.pem 

# alternatively, generate dh parameters yourself (takes really long)
# openssl dhparam -check -out /etc/nginx/crypto/dhparam.pem 4096
