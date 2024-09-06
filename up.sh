#!/usr/bin/env bash

export MYSQL_INITIAL_ROOT_PASSWORD=$(tr -dc 'A-Za-z0-9_' < /dev/urandom | head -c 32)
docker compose up -d && docker ps --all
unset MYSQL_INITIAL_ROOT_PASSWORD

