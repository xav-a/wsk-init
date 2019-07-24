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

# Upgrade disk image and install vim, curl, pip3 & nginx
set -x
apt update -y && apt upgrade -y
python -m pip install numpy --user
apt install vim curl python3-pip nginx -y
service nginx stop
set +x

echo -e "set number\nset tabstop=4\nset shiftwidth=4\nset expandtab\nset hlsearch\n" >> ~/.vimrc
echo -e "SETUP ./~vimrc"

# scala syntax hightlighting
mkdir -p ~/.vim/{ftdetect,indent,syntax} && \
for d in ftdetect indent syntax; do
    wget -O ~/.vim/$d/scala.vim https://raw.githubusercontent.com/derekwyatt/vim-scala/master/$d/scala.vim > /dev/null;
done
echo -e "SETUP scala.vim at ~/.vim\n"


set -x
export SRC_DIR="/usr/local/src"
export TMP_LVM="/dev/mapper/emulab-wsklvm" # Logical volume location
export OPENWHISK_HOME="${SRC_DIR}/openwhisk" # OpenWhisk location
export OPENWHISK_TMP_DIR="/opt/openwhisk/tmp"
export DOCKER_DIR="/dockerdata"
export PIPBENCH="${SRC_DIR}/pipbench"
set +x


echo -e "CREATE & MOUNT logical volume at ${DOCKER_DIR}...\n"
if [ -e "${TMP_LVM}" ];
then
    echo "Logical volume already exists (${TMP_LVM}), skipping ..."
else
    lvcreate -L 30G emulab -n wsklvm
    echo 'TMP_LVM="'${TMP_LVM}'"' | tee -a /etc/environment
fi
# Mount logical volume
if [ -e "${DOCKER_DIR}" ];
then
    echo "Cannot mount ${TMP_LVM} filesystem at ${DOCKER_DIR}, skipping ..."
else
    mkdir ${DOCKER_DIR}
    mkfs.ext4 ${TMP_LVM}
    mount ${TMP_LVM} ${DOCKER_DIR}
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
    echo 'ACT_DIR="'${SRC_DIR}'/actions"' | tee -a /etc/environment

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

echo -e "DOWNLOAD & SETUP PIPBench...\n"
cd ${SRC_DIR}
if [ -f ${PIPBENCH} ];
then
    echo "PIPBENCH already installed ($PIPBENCH), skipping..."
else
    (cd ${SRC_DIR} && git clone https://github.com/xav-a/pipbench.git pipbench &&
        cd pipbench &&  git checkout wsk-support)
    echo 'PIPBENCH="'${PIPBENCH}'"' | tee -a /etc/environment
    set -x
    pip3 install --upgrade pip==19.1
    python3 -m pip install numpy grequests requests
    set +x

    (${HOME}/pipbench_setup.sh ${PIPBENCH})
fi




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
