# pg-ledger

For more information, please see the [Wiki](https://github.com/TobiasBengtsson/pg-ledger/wiki).

## Install

Create a new postgres database and execute `db.pgsql` within that database.

## Run tests

The easiest way is though docker:

```
docker build -t pg-ledger .
docker run --name pg-ledger-test -d pg-ledger
docker exec pg-ledger-test sh -c 'chmod 0500 /tmp/source/test.sh'
docker exec pg-ledger-test sh -c '/tmp/source/test.sh'
```
