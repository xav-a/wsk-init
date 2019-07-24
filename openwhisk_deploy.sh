#!/bin/bash
ME=`basename "$0"`

# Make sure variable is set
if [ -z "${OPENWHISK_HOME}" ]; then
    echo -e "OPENWHISK_HOME environment variable not set\n"
    exit 1
elif [ $# -gt 0 ]; then
    echo -e "Too many arguments\n"
    exit 1
fi

# Name of config file openwhisk optinally reads from to set
# some of the deployment specs
CONFIG=intellij-run-config.groovy
if [ ! -f "${OPENWHISK_HOME}/${CONFIG}" ]; then
    echo -e "WARNING: No \e[1m${CONFIG}\e[0m file found in ${OPENWHISK_HOME}\n"
fi

set -xe
# Deploy openwhisk
cd ${OPENWHISK_HOME}/ansible
ansible-playbook -i environments/local setup.yml

cd ..
./gradlew distDocker

cd ansible
ansible-playbook -i environments/local couchdb.yml && \
ansible-playbook -i environments/local initdb.yml && \
ansible-playbook -i environments/local wipe.yml && \
ansible-playbook -i environments/local openwhisk.yml

# installs a catalog of public packages and actions
ansible-playbook -i environments/local postdeploy.yml

# to use the API gateway
ansible-playbook -i environments/local apigateway.yml
ansible-playbook -i environments/local routemgmt.yml

# Config wsk-cli
cd ..
cp bin/wsk /usr/local/bin
wsk property set --apihost 172.17.0.1
wsk property set --auth `cat ansible/files/auth.guest`
wsk property get --auth

wsk action invoke /whisk.system/utils/echo -p message hello --result -i

# eval "`wsk sdk install bashauto --stdout`"
exit 0
