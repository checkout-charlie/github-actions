#!/bin/sh

set -e

COMMAND="$4"
ENV_FILE="$5"
SERVICE_PORT="$6"
SERVICE_PATH="$7"

printenv
yarn install
yarn lint
yarn build --modern=client
yarn start-server-and-test 'yarn start' "http://localhost:$SERVICE_PORT$SERVICE_PATH" "$COMMAND"
