# GitLab Docker Build Script

This Dockerfile will create a new Docker container running GitLab 6.2 on Ubuntu 13.10.

## Installation

Follow these instructions to download or build GitLab.


### Step 0: Install Docker

[Follow these instructions](http://www.docker.io/gettingstarted/#h_installation) to get Docker running on your server.


### Step 1: Build GitLab

Clone repository:

    git clone https://github.com/yep/gitlab-docker.git
    cd gitlab-docker

Edit the `firstrun.sh` script and change the variables:

 * `POSTGRES_PASS` to a new, random password for postgresql
 * `DOMAIN_NAME` to the fully qualified domain name of your server

Start the build:

    docker build -t gitlab .

Note that since GitLab has a large number of dependencies, both pulling from the index or running the build process will take a while, although pulling should be somewhat faster.


### Step 2: Create A New Container Instance

This build makes use of Docker's ability to map host directories to directories inside a container. It does this so that a user's custom configuration can be injected into the container at first start. In addition, since the data is stored outside the container, it allows a user to put the folder on faster storage such as an SSD for higher performance.

To create the container instance, replace `PATH/TO/gitlab-docker` with the absolute path of your git repository clone and run the following:

    cd PATH/TO/gitlab-docker
    docker run -d -v PATH/TO/gitlab-docker:/srv/gitlab gitlab


### Step 3: Change default gitlab admin password

Log in to your new docker install using the account below, change its password and optionally its email address, too:

    login: admin@local.host
    password: 5iveL!fe


### Step 4: Trust https certificate

The setup redirects http requests to https and uses a self signed https certificate. In order to be sure you are connecting to the correct host with https, check the https certificate fingerprint.

Display https certifcate SHA-1 fingerprint (replace CONTAINER_ID):

    docker logs CONTAINER_ID 2>&1 | grep Fingerprint

Distribute this fingerprint to everybody who is going to use the server. They can then each check if the SHA-1 fingerprint shown by their browser is correct.

It is recommended to permanently trust the self signed certificate so you can notice if it should change unintentionally some day. How to trust the certificate permanently depends on the browser you use.

On OS X with Chrome version 30, permanently trust the certificate like this:

 * Click on the padlock icon next to the URL of your server
 * In tab `connection` press on `certificate information`
 * Drag and drop the certificate icon to your desktop
 * Double click the certificate file with file extension .cer to add it to your keychain permanently
 * Restart Chrome


## Experimental: GitLab update via container rebuild

It should be possible to use updates to this build to update a GitLab server. The process is as follows:

1. Ether pull an updated version of this script from the Docker index, or git pull this repo and rebuild.
2. Stop your current instance, and remove it with docker rm.
3. Inside the gitlab-docker/ folder from the install steps, run *git checkout firstrun.sh* to restore the firstrun.sh script.
4. Edit the firstrun.sh and delete the section titled "Delete this section if restoring data from previous build." Replace this section with the code to run any necessary database migrations for the new version.
5. Rerun the process from step 3 of the installation instructions.

Note that while this process has been mostly tested, it has not yet been tested with DB migrations. As with any time you perform software updates, [do a backup](https://github.com/gitlabhq/gitlabhq/blob/master/doc/raketasks/backup_restore.md) first.
