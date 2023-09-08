#!/bin/sh

set -e

COMMAND="$4"
ENV_FILE="$5"
SERVICE_PORT="$6"

pwd
ls -als

. "./$ENV_FILE"
printenv
yarn install
yarn lint
yarn add start-server-and-test
yarn build --modern=client
yarn start-server-and-test start "http://localhost:$SERVICE_PORT" "$COMMAND" --timeout $READINESS_TIMEOUT
