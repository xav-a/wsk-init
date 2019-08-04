#!/bin/bash
ME=`basename $0`

if [ $# -eq 0 ]; then
    echo -e "\n"\
"Usage: $ME <source dir>

    <source dir>    Path to directory for the installation's src code/repos\n"
elif [ $# -gt 1 ]; then
    echo -e "(${ME}) Too many arguments"
    exit 1
fi

export SRC_DIR=$1

if [ ! -d "${SRC_DIR}" ]; then
    echo -e "${SRC_DIR} DOES NOT EXIST, using default '/usr/local/src'\n"
fi

set -x
export SRC_DIR="/usr/local/src"
export OPENWHISK_HOME="${SRC_DIR}/openwhisk" # OpenWhisk location
export OPENWHISK_TMP_DIR="/opt/openwhisk/tmp"
export EXTRA_STORE="/extra"
export DOCKER_DIR=${EXTRA_STORE}
set +x


if [ -e "${EXTRA_STORE}" ];
then
    echo "${EXTRA_STORE} exists, skipping..."
else
    mkdir ${EXTRA_STORE}
    /usr/local/etc/emulab/mkextrafs.pl ${EXTRA_STORE}
    echo 'EXTRA_STORE="'${EXTRA_STORE}'"' | tee -a /etc/environment

    mkdir ${DOCKER_DIR}/docker-tmp ${DOCKER_DIR}/docker-aufs
fi

cd ${SRC_DIR}

# Clone and Export repo location
echo -e "DOWNLOAD & SETUP OpenWshisk...\n"
if [ -f "${OPENWHISK_HOME}" ];
then
	echo "OPENWHISK already installed (${OPENWHISK_HOME}), skipping ..."
else
    git clone https://github.com/xav-a/incub-openwhisk-sch.git openwhisk
	echo 'OPENWHISK_HOME="'${OPENWHISK_HOME}'"' | tee -a /etc/environment

    # Make DIR to hold actions
    cp -r $HOME/actions/ ${SRC_DIR}

    # Install openwhisk dep
    cd ${OPENWHISK_HOME}/
    # git checkout testchanges
    echo Installing Openwhisk Deps
    (cd tools/ubuntu-setup && ./all.sh)

    # Set docket opts to use mount point as image installation dir
    service docker stop
    echo 'export TMPDIR="'${DOCKER_DIR}'/docker-tmp"' | tee -a /etc/default/docker
    echo 'DOCKER_OPTS="$DOCKER_OPTS -g '${DOCKER_DIR}'/docker-aufs"' | tee -a /etc/default/docker
    service docker start
fi
# Export tmp dir location
if [ -f "${OPENWHISK_TMP_DIR}" ];
then
	echo "Can't set WSK TMP directory (${OPENWHISK_TMP_DIR}), skipping"
else
	mkdir -p ${OPENWHISK_TMP_DIR}
	echo 'OPENWHISK_TMP_DIR="'${OPENWHISK_TMP_DIR}'"' | tee -a /etc/environment
fi


echo -e "DEPLOY OpenWhisk...\n"
(${HOME}/openwhisk_deploy.sh)

# Deploy openwhisk

# Create Image
# cd $OPENWHISK_HOME
# gradle :core:controller:distDocker -PdockerImageTag=testController

# Swap component
# docker stop [CONTAINER]
# ansible-playbook -i environments/local/ controller.yml -e docker_image_tag=testController
# wsk action invoke /whisk.system/utils/echo -p message hello --result -i

# Unmount and delete logical volume
# service docker stop
# umount /dockerdata/
# lvremove $TMP_LVM

# read -n 1 -s -r -p "Press any key to continue"
