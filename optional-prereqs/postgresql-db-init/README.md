To create GCD, ICNDB and OS1DBs in the target PostgreSQL deployment, execute the following:

```bash
oc cp ./create-postgresql-dbs.sql postgresql/$(oc get pods --namespace postgresql -o name | cut -d"/" -f2):/usr/create-postgresql-dbs.sql
oc --namespace postgresql exec deploy/postgresql -- /bin/bash -c 'mkdir /pgsqldata/icn'
oc --namespace postgresql exec deploy/postgresql -- /bin/bash -c 'chown postgres:postgres /pgsqldata/icn'
oc --namespace postgresql exec deploy/postgresql -- /bin/bash -c 'mkdir /pgsqldata/gcd'
oc --namespace postgresql exec deploy/postgresql -- /bin/bash -c 'chown postgres:postgres /pgsqldata/gcd'
oc --namespace postgresql exec deploy/postgresql -- /bin/bash -c 'mkdir /pgsqldata/os1'
oc --namespace postgresql exec deploy/postgresql -- /bin/bash -c 'chown postgres:postgres /pgsqldata/os1'
oc --namespace postgresql exec deploy/postgresql -- /bin/bash -c \
'psql postgresql://cpadmin:Password@localhost:5432/postgresdb \
--file=/usr/create-postgresql-dbs.sql'
```

Run the following to validate all the databases were created correctly

```bash
oc --namespace postgresql exec deploy/postgresql -- /bin/bash -c \
'psql postgresql://cpadmin:Password@localhost:5432/postgresdb -l'
```