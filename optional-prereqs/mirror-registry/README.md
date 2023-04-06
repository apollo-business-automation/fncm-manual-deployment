* Follow the guide: https://docs.openshift.com/container-platform/4.10/installing/disconnected_install/installing-mirroring-installation-images.html
* Pull Secret download from: https://console.redhat.com/openshift/install/pull-secret
* Download Mirror Registry for Red Hat OpenShift: https://console.redhat.com/openshift/downloads#tool-mirror-registry
* Download OpenShift Client mirror plugin: https://console.redhat.com/openshift/downloads#tool-mirror-registry
* As a helper, there is also [bash script](mirror-registry.sh) that can push images directly into your image registry on ocp
* podman login -u init -p password bastion:8443 --tls-verify=false
* echo -n "init:password" | base64
* oc mirror --config=./imageset-config.yaml docker://bastion.localhost:8443 --dest-skip-tls