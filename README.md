# FileNet Content Manager Production deployment manual installation ✍️<!-- omit in toc -->

## Disclaimer ✋

This is **not** an official IBM documentation.  
Absolutely no warranties, no support, no responsibility for anything.  
Use it on your own risk and always follow the official IBM documentations.  
It is always your responsibility to make sure you are license compliant when using this repository to install FileNet Content Manager.

Please do not hesitate to create an issue here if needed. Your feedback is appreciated.

Not for production use. Suitable for Demo and PoC environments - but with Production deployment.  

## Version

**This guide is written for the 5.5.8 version of FileNet Content Manager**

## Prerequisites

Based on the [Preparing your cluster documentation](https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=deployments-v555-later-preparing-your-cluster).

- OpenShift Container Platform (OCP) cluster version 4.8 and later with sufficient resources
- (For Online Installation) IBM entitlement key from https://myibm.ibm.com/products-services/containerlibrary
- (mandatory) File RWX Storage Class
- (optional) Block RWO Storage Class
- Cluster admin user
- Cluster non-admin user
- External Systems Connectivity
  - Database
  - LDAP
  - S3 (when using S3 for advanced storage area)

## Needed tooling

- oc
- podman
- git


## Side-by-side Scenario
### Prepare

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=deployments-v555-later-preparing-your-cluster

#### Local repo setup

**Needed for the Air Gap installation where the target OpenShift Container Platform has no internet connectivity**

**First option is to mirror images from cp.icr.io**
Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=gaci-v559-later-getting-access-images-from-local-image-registry 

You will need a client machine (for example Bastion node) with access both to the internet and to your local image registry.

**With ibm-pak**

Based on https://www.ibm.com/docs/en/cloud-paks/1.0?topic=plugin-installing-by-connected-disconnected-mirroring and 
https://www.ibm.com/docs/en/cpfs?topic=plugin-cloudctl-case-corresponding-pak-commands  

```bash
oc login https://<cluster-ip>:<port> -u <cluster-admin> -p <password>
curl -L https://github.com/IBM/ibm-pak/releases/download/v1.5.2/oc-ibm_pak-linux-amd64.tar.gz -o oc-ibm_pak-linux-amd64.tar.gz
tar -xf oc-ibm_pak-linux-amdd64.tar.gz
mv oc-ibm_pak-linux-amd64 /usr/local/bin/oc-ibm_pak
export CASE_NAME=ibm-cp-fncm-case
export CASE_VERSION=1.4.0
export NAMESPACE=ibm-cp-fncm
export CASE_INVENTORY_SETUP=fncmOperatorSetup
# Your registry url, shouldn't be ocp internal
export TARGET_REGISTRY=<your registry>
oc ibm-pak config repo 'IBM Cloud-Pak OCI registry' -r oci:cp.icr.io/cpopen --enable
# To download the case
oc ibm-pak get \
$CASE_NAME \
--version $CASE_VERSION
# or $TARGET_REGISTRY/$ORGANIZATION for certain organisation
oc ibm-pak generate mirror-manifests \
   $CASE_NAME \
   $TARGET_REGISTRY \
   --version $CASE_VERSION

# to list mirrored images
oc ibm-pak describe $CASE_NAME --version $CASE_VERSION --list-mirror-images
# Login to your target container registry, shouldn't be OCP internal one
podman login $TARGET_REGISTRY -u <username> -p <password>
# Get the entitlement key from https://myibm.ibm.com/products-services/containerlibrary and use it as a password (in the -p <password>)
podman login cp.icr.io -u cp -p <password>
export REGISTRY_AUTH_FILE=$HOME/.docker/config.json


oc image mirror \
 -f ~/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/images-mapping.txt \
 --filter-by-os '.*'  \
 -a $REGISTRY_AUTH_FILE \
 --insecure  \
 --skip-multiple-scopes \
 --max-per-registry=1 \
 --continue-on-error=true


oc ibm-pak launch \
$CASE_NAME \
 --version $CASE_VERSION \
 --action install-operator \
 --inventory $CASE_INVENTORY_SETUP \
 --namespace $NAMESPACE \
 --tolerance 1
```


**Second Option is to download images from Passport Advantage**
Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=gaci-v558-earlier-getting-access-images-from-passport-advantage

Download the packages from PPA and load the images. [IBM Passport Advantage (PPA)](https://www-01.ibm.com/software/passportadvantage/pao_customer.html) provides archives (.tgz) for the software. To view the list of Passport Advantage eAssembly installation images, refer to the download document.
* M03N7ML IBM FileNet Content Platform Engine V5.5.8 Linux x86 Container Multilingual (mandatory)
* M03N9ML IBM FileNet Content Manager Operator V5.5.8 Linux x86 Container Multilingual (mandatory)
* M03NHML FileNet Content Search Services V5.5.8 Linux x86 Container Multilingual (optional)
* M03NVML IBM Content Navigator V3.0.11 Linux x86 Container Multilingual (mandatory)
* M03N8ML IBM FileNet Content Services GraphQL API V5.5.8 Linux x86 Container Multilingual (mandatory)
* G01J0ML IBM FileNet CMIS V3.0.6 Linux x86 Container Multilingual (optional)


```bash
git clone -b 5.5.8 https://github.com/ibm-ecm/container-samples
cd container-samples
oc login https://<cluster-ip>:<port> -u <cluster-admin> -p <password>
podman login $(oc registry info) -u <administrator> -p $(oc whoami -t) 
cd scripts
# login as the builder account which has permissions to push and pull on the image registry, or use any other user that is appropriate
oc registry login -z builder 
./loadimages.sh -p <PPA-ARCHIVE>.tgz  -r $(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')/cp/cp4a/fncm/
oc get is
```

Additionally, if you want to upgrade on the certain fix pack, please download the respective containers from the [IBM Fix Central](https://www.ibm.com/support/fixcentral), make sure you search there for Container versions of Fix Packs and for 5.5.8 version of FileNet and 3.0.11 version of IBM Content Navigator. Also, leverage the following [FileNet P8 Fix Pack Compatibility Matrices](https://www.ibm.com/support/pages/filenet-p8-fix-pack-compatibility-matrices) which shows not only versions of fix packs, but also image tags and versions for use in the deployment later.

And then you need to provide the mapping to go to internal OpenShift image registry for the FNCM container images instead of the public one.

```bash
oc apply -f image-content-source-policy.yaml
```

#### Gathering the values for the installation (When moving from traditional)

Follow https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=mfpcwfcme-preparing-your-source-filenet-content-manager-environment-move 

The following is example, not exhaustive, of what is required to be gathered:

* [Gather information about Storage and Advanced Storage Areas](https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=move-arranging-your-storage)
* [Gather information about Directory Server](https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=move-gathering-values-your-custom-resource-definition)
* [Gather information about Object Stores](https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=move-gathering-values-your-custom-resource-definition)
* [Backup the IBM Configuration DB and Directory](https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=move-backing-up-content-navigator-configuration-directory)

#### Gathering Certificates

For any external service that TLS should be used for, CRT file has to be downloaded and added to the trusted certificates in the customer resource definition for FileNet. (Example can be S3 buckets, secured DB or LDAP connections etc.)

#### Directory Server

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=environment-authenticating-authorizing-in-filenet-content-manager 

#### FNCM DB

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=environment-preparing-target-filenet-content-manager 

As stated "This task doesn't apply in a move scenario because your databases are already configured to support your source environment. However, the additional tasks for creating secrets for SSL configuration data are required".

**For the DB2:** https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=pppd-creating-secrets-protect-sensitive-db2-ssl-configuration-data

#### ICN DB

ICN on Containers should have separate DB and everything recreated based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=environment-preparing-target-filenet-content-manager where it is stated that **"If your scenario includes maintaining a traditional WebSphere Application Server deployment alongside the container deployment, you need an additional configuration database for Navigator in the container environment"**

**Prepare 1 DB** - ICN and access user permissions that you normally do and also review the SSL configuration, here for DB2:  https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=pcnd-creating-secrets-protect-sensitive-db2-ssl-configuration-data

#### Create project for the deployment

```bash
oc new-project filenet
```

#### Secrets

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=deployments-creating-secrets-protect-sensitive-configuration-data

**FNCM secret** 
Values need to be adjusted to real ones. OS1 is a general object store, replace with yours, any number of Object Stores can be provided here.
```bash
oc -n filenet create secret generic ibm-fncm-secret \
--from-literal=gcdDBUsername="{{ DB username for GCD }}" \
--from-literal=gcdDBPassword="{{ DB password for GCD }}" \
--from-literal=os1DBUsername="{{ DB username for OS1 }}" \
--from-literal=os1DBPassword="{{ DB password for OS1 }}" \
--from-literal=appLoginUsername="{{ Username of CPE/ICN admin user who is available in AD }}" \
--from-literal=appLoginPassword="{{ Password of CPE/ICN admin user who is available in AD }}" \
--from-literal=keystorePassword="{{ Password for Keystore}}" \
--from-literal=ltpaPassword="{{ Password for LTPA }}"
```

**ICN secret**
Values need to be adjusted to real ones. **The recommendation is to use a different DB then the traditional ICN is going to use, import the configuration from the traditional ICN and use them in parallel if needed.** This is due to the changes in the container ICN DB schema.
```bash
oc -n filenet create secret generic ibm-ban-secret \
--from-literal=navigatorDBUsername="{{ DB username for ICN }}" \
--from-literal=navigatorDBPassword="{{ DB password for ICN }}" \
--from-literal=keystorePassword="{{ Password for Keystore}}" \
--from-literal=ltpaPassword="{{ Password for LTPA }}" \
--from-literal=appLoginUsername="{{ Username of CPE/ICN admin user who is available in AD }}" \
--from-literal=appLoginPassword="{{ Password of CPE/ICN admin user who is available in AD }}"
```

**Root CA secret**
- not in our deployment

**External TLS Secrets** (such as for S3)
https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=services-importing-certificate-external-service 

**LDAP Bind User Secret** 
Values need to be adjusted to real once.
```bash
oc -n filenet create secret generic ldap-bind-secret \
--from-literal=ldapUsername="{{ LDAP username for Bind }}" \
--from-literal=ldapPassword="{{ LDAP password for Bind }}" 
```    

**LDAP SSL Secret**
https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=environment-configuring-ssl-enabled-ldap 

#### Storage

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=deployments-configuring-storage-content-services-environment

For this deployment StorageClass dynamic provisioning is used as documents are stored in S3. (https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=environment-creating-volumes-folders-deployment)

### Operator Storage

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=operator-preparing-storage

Based on dynamically descriptors/operator-shared-pvc.yaml. Removed storageClass annotation in favor of parameter.

Values need to be adjusted to real ones ({{ RWX StorageClass name }})
```bash
oc -n filenet create -f operator-shared-pvc.yaml
```

### Getting access to container images

**When not using Air Gap installation**

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=deployments-getting-access-container-images

Get entitlement key from https://myibm.ibm.com/products-services/containerlibrary

```bash
oc -n filenet create secret docker-registry admin.registrykey --docker-server=cp.icr.io --docker-username=cp --docker-password="{{ ICR key }}"
```

**When using your own registry**

```bash
oc -n filenet create secret docker-registry admin.registrykey --docker-server=<your registry> --docker-username=<your user> --docker-password=<your password>
```


### Deploying the Operator

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=operator-v557-v558-deploying-interactively-silently

**For AirGap with OCP Internal Registry**

```bash
# get service account able to download container images when using airgap
oc project filenet
oc create sa image-puller 
oc adm policy add-cluster-role-to-user system:image-puller -z image-puller 
oc sa new-token image-puller
```

In the part bellow, use `image-puller` as the image registry user and token as the password.

**Using the provided script**

```bash
cd container-samples/scripts
# For silent installation, edit ./silentInstallVariables.sh and source it before the next command
./deployOperator.sh
# Finish the script installation and then monitor the operator pod until STATUS = running
oc get pods -w 
```

**For Manual without the Script above**

```bash
oc apply -f ./fncm_v1_fncm_crd.yaml # this one performed by Cluster Admin, the rest by Project admin
oc apply -f ./service_account.yaml
oc apply -f ./role.yaml
oc apply -f ./role_binding.yaml
oc apply -f ./operator.yaml
```

Copy JDBC drivers to PVC

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=operator-v555-v556-preparing-storage
```text
pv-root-dir
   └── jdbc
      ├── oracle
          └── ojdbc8.jar
```

Replace file ./jdbc/oracle/ojdbc8-stub.txt with real ojdbc8.jar

Upload jdbc folder to Operator.
```bash
pod=`oc get pod -l name=ibm-fncm-operator -o name | cut -d"/" -f 2`
echo $pod
oc cp jdbc $pod:/opt/ansible/share/**jdbc**

Copy JDBC drivers to PVC

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=operator-preparing-storage
```text
pv-root-dir
   └── jdbc
      ├── db2
          └── db2jcc4.jar
          └── db2jcc_license_cu.jar
```

Upload jdbc folder to Operator.

```bash
cd container-samples/scripts
mkdir ./jdbc/db2
cp <path-to-db2jcc4.jar> ./jdbc/db2/
cp <path-to-db2jcc_license_cu.jar> ./jdbc/db2/
pod=`oc get pod -l name=ibm-fncm-operator -o name | cut -d"/" -f 2`
echo $pod
oc cp jdbc/db2 $pod:/opt/ansible/share/jdbc
```

### Create CR

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=resource-creating-custom

CR is file *ibm_fncm_my_cr_production.yaml* (*ibm_fncm_cr_production_FC_content.yaml* can be used for reference)

Must review and fill all ```<something>``` places.
Review whole ldap_configuration for changes specific to your AD.

- Added initialization - must be omitted with existing Storage and DBs
- CPE and ICN image tags set to newer than original GitHub based on compatibility excel from https://www.ibm.com/support/pages/filenet-p8-fix-pack-compatibility-matrices
- Licenses need to be adjusted to your actual ones - ICF.UVU

### Apply CR

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=resource-applying-custom

Deployment takes some time.
```bash
oc apply -f ibm-fncm-my-cr-production.yaml
```

May need to update NetworkPolicy fncmdeploy-default-deny when created to permit all and restart operator if there are errors that operator cannot communicate with LDAP and DB.  
Based on https://kubernetes.io/docs/concepts/services-networking/network-policies/#allow-all-ingress-traffic
```yaml
spec:
  ingress:
  - {}
  egress:
  - {} 
```

Errors in the Operator log can be searched by either *Playbook task failed* or *31m* keywords. Please Note that this Operator is actually the one for CP4BA and it also lists some task for other components then FNCM and ICN only. Unfortunately in this version some other components ansible tasks are breaking even when we are not deploying them making Operator log less readable - but I can help with that/clarify.

### Post-deployment

Based on https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=environment-completing-post-deployment-tasks

### Copy operator

In case of Operator code debugging is needed.

```bash
pod=`oc get pod -l name=ibm-fncm-operator -o name | cut -d"/" -f 2`
oc cp $pod:/opt/ansible/roles roles
```
