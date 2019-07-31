# Create Image
export OPENWHISK_HOME=/usr/local/src/openwhisk
cd $OPENWHISK_HOME
./gradlew :core:controller:distDocker -PdockerImageTag=testController

# Swap component
service docker stop
cd ansible
ansible-playbook -i environments/local controller.yml -e mode=clean
service docker start
ansible-playbook -i environments/local/ controller.yml -e docker_image_tag=testController
wsk action invoke /whisk.system/utils/echo -p message hello --result -i
