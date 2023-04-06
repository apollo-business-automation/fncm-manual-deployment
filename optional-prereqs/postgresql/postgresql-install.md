Create postgresql Project
```bash
oc new-project postgresql
```

Add required privileged premission
```bash
oc apply -f postgresql-anyuid.yaml
```

Create Secret for config
```bash
oc apply -f postgresql-secret.yaml
```

Create PVC for data
```bash
oc apply -f postgresql-pvc-data.yaml
```

Create PVC for table spaces as they should not be in PGDATA
```bash
oc apply -f postgresql-pvc-pgdata.yaml
```

Create Deployment
```bash
oc apply -f postgresql-deployment.yaml
```

Create Service
```bash
oc apply -f postgresql-service.yaml
```

Wait for pod in postgresql Project to become Ready 1/1.

Set max transactions
```bash
# Set the value
oc --namespace postgresql exec deploy/postgresql -- /bin/bash -c \
'psql postgresql://cpadmin:UGFzc3dvcmQ=@localhost:5432/postgresdb \
-c "ALTER SYSTEM SET max_prepared_transactions = 200;"'

# Restart the pod
oc --namespace postgresql delete pod \
$(oc get pods --namespace postgresql -o name | cut -d"/" -f2)
```

Wait for pod in postgresql Project to become Ready 1/1.