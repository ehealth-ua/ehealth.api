#!/bin/sh
# `pwd` should be /opt/graphql
APP_NAME="graphql"

if [ "${DB_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/$APP_NAME command Elixir.Core.ReleaseTasks migrate
fi;

if [ "${DB_SEED}" == "true" ]; then
  echo "[WARNING] Seeding database!"
  ./bin/$APP_NAME command Elixir.Core.ReleaseTasks seed
fi;
