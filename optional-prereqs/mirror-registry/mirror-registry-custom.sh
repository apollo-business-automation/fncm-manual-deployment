#!/bin/bash
# OSX, LINUX
PLATFORM='OSX'
LOCAL_SECRET_JSON='./pull-secret.json'
OCP_RELEASE='4.10.54'
LOCAL_REGISTRY='image-registry.openshift-image-registry.svc:5000'
LOCAL_REPOSITORY='ocp4/openshift4'
PRODUCT_REPO='openshift-release-dev'
RELEASE_NAME='ocp-release'
ARCHITECTURE='x86_64'
# IMAGE_REGISTRY_CERTS_SECRET='router-certs-default'
IMAGE_REGISTRY_CERTS_SECRET='letsencrypt-certs'

read -r -p "Do you want to expose the registry for the mirror? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
    HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
    ESCAPED_HOST=$(printf '%s\n' "$HOST" | sed -e 's/[]\/$*.^[]/\\&/g')
    ESCAPED_LOCAL_REGISTRY=$(printf '%s\n' "$LOCAL_REGISTRY" | sed -e 's/[]\/$*.^[]/\\&/g')
    sed -i -e "s/$ESCAPED_LOCAL_REGISTRY/$ESCAPED_HOST/" $LOCAL_SECRET_JSON
    LOCAL_REGISTRY=$HOST
    if [[ "$response" =~ ^([lL][Ii][Nn][Uu][Xx])$ ]]
    then
        oc get secret -n openshift-ingress $IMAGE_REGISTRY_CERTS_SECRET -o go-template='{{index .data "tls.crt"}}' | base64 -d | sudo tee /etc/pki/ca-trust/source/anchors/${HOST}.crt  > /dev/null
        sudo update-ca-trust enable
    fi
fi

read -r -p "Do you want to run the dry run of the mirror? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    oc adm release mirror -a ${LOCAL_SECRET_JSON}  \
        --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
        --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
        --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} --dry-run
fi

read -r -p "Do you want to start with the mirror? [y/N] " response
if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]
then
    exit
fi

oc registry login -z builder 

oc adm release mirror -a ${LOCAL_SECRET_JSON}  \
     --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
     --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
     --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}

read -r -p "Do you want to de-expose the registry for the mirror? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":false}}' --type=merge
fi