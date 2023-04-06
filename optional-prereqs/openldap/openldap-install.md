Add helm repository for OpenLdap
```bash
helm repo add helm-openldap https://jp-gouin.github.io/helm-openldap/
```

Review and adjust openldap-values.yaml file which defines the whole deployment.
```bash 
cat openldap-values.yaml
```

Create openldap Project
```bash
oc new-project openldap
```

Add required anyuid premission
```bash
oc apply -f openldap-cluster-role.yaml
```

Install OpenLdap
```bash
helm install openldap helm-openldap/openldap-stack-ha \
-f ./openldap-values.yaml -n openldap --version 3.0.2
```

Add Route for phpLdapAdmin
```bash
oc apply -f openldap-route.yaml
```

Wait for all pods in openldap Project to be Ready 1/1.