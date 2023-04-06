-- create user gcd
CREATE ROLE gcd WITH INHERIT LOGIN ENCRYPTED PASSWORD 'Password';

-- create database gcd
create database gcd owner gcd template template0 encoding UTF8 ;
revoke connect on database gcd from public;
grant all privileges on database gcd to gcd;
grant connect, temp, create on database gcd to gcd;

-- please modify location follow your requirement
create tablespace gcd_tbs owner gcd location '/pgsqldata/gcd';
grant create on tablespace gcd_tbs to gcd;

-- create user os1
CREATE ROLE os1 WITH INHERIT LOGIN ENCRYPTED PASSWORD 'Password';

-- create database os1
create database os1 owner os1 template template0 encoding UTF8 ;
revoke connect on database os1 from public;
grant all privileges on database os1 to os1;
grant connect, temp, create on database os1 to os1;

-- please modify location follow your requirement
create tablespace os1_tbs owner os1 location '/pgsqldata/os1';
grant create on tablespace os1_tbs to os1;

-- create user icn
CREATE ROLE icn WITH INHERIT LOGIN ENCRYPTED PASSWORD 'Password';

-- create database icn
create database icn owner icn template template0 encoding UTF8 ;
revoke connect on database icn from public;
grant all privileges on database icn to icn;
grant connect, temp, create on database icn to icn;

-- please modify location follow your requirement
create tablespace icn_tbs owner icn location '/pgsqldata/icn';
grant create on tablespace icn_tbs to icn;