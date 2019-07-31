#!/bin/bash

# Upgrade disk image and install vim, curl, pip3 & nginx
set -x
apt update -y && apt upgrade -y
python -m pip install numpy --user
apt install vim curl python3-pip nginx -y
service nginx stop
set +x

if [[ -z "${PIPBENCH}" ]]; then
    PIPBENCH=$1
fi
cd $PIPBENCH

PKGS=25
HDLR=50
dd bs=1024 count=100000 </dev/urandom > random.dat
(cd graph_resizing && python resize.py $PKGS)

python3 generate_packages.py graph_resizing/new-graph-$PKGS.json random.dat

shuf -i 1-$PKGS -n $HDLR > imports_per_handler.txt
python3 generate_handlers.py graph_resizing/new-graph-$PKGS.json imports_per_handler.txt -b openwhisk -n $HDLR

cp -r web/ /tmp/
cp nginx.conf /tmp/web/
(cd /tmp/web && nginx -c $(pwd)/nginx.conf)

./register_handlers.sh $PIPBNECH/handlers
