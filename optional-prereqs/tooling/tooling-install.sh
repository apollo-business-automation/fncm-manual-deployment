#!/bin/bash
cd /usr
yum install ncurses -y;
curl -O https://download.java.net/java/GA/jdk9/9/binaries/openjdk-9_linux-x64_bin.tar.gz;
tar -xvf openjdk-9_linux-x64_bin.tar.gz;
ln -fs /usr/jdk-9/bin/java /usr/bin/java;
ln -fs /usr/jdk-9/bin/keytool /usr/bin/keytool;
curl -O https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz;
tar -zxvf helm-v3.6.0-linux-amd64.tar.gz linux-amd64/helm;
mv linux-amd64/helm helm;
chmod u+x helm;
ln -fs /usr/helm /usr/bin/helm;
curl -LO https://github.com/mikefarah/yq/releases/download/v4.30.5/yq_linux_amd64.tar.gz;
tar -xzvf yq_linux_amd64.tar.gz;
ln -fs /usr/yq_linux_amd64 /usr/bin/yq;
podman -v;
java -version;
keytool;
helm version;
oc version;
kubectl version;
yq --version;