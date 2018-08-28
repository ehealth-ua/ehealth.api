#!/bin/sh
# `pwd` should be /opt/ehealth
APP_NAME="ehealth"

if [ "${DB_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/$APP_NAME command Elixir.EHealth.ReleaseTasks migrate
fi;

if [ "${DB_SEED}" == "true" ]; then
  echo "[WARNING] Seeding database!"
  ./bin/$APP_NAME command Elixir.EHealth.ReleaseTasks seed
fi;
