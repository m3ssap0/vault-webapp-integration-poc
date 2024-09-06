#!/usr/bin/env bash

export MYSQL_INITIAL_ROOT_PASSWORD=
docker compose down && docker image rm \
    vault-webapp-integration-poc-vault-init \
    vault-webapp-integration-poc-database \
    vault-webapp-integration-poc-vault-server \
    vault-webapp-integration-poc-webapp
unset MYSQL_INITIAL_ROOT_PASSWORD

