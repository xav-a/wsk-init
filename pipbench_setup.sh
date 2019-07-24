#!/bin/bash


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
