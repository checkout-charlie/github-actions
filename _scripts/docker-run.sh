#!/bin/sh

set -e

IMAGE_NAME="$1"
IMAGE_TAG="$2"
COMMAND="$3"
ENV_FILE="$4"
RUN_ARGS="$5"
ENTRYPOINT_OVERRIDE="$6"

if [ -z "$ENTRYPOINT_OVERRIDE" ]; then
  docker run --rm --env-file "$ENV_FILE" $RUN_ARGS "$IMAGE_NAME:$IMAGE_TAG" $COMMAND
else
  entrpoint_cmd="${ENTRYPOINT_OVERRIDE% *}"
  entrpoint_args="${ENTRYPOINT_OVERRIDE#* }"

  echo "First part: $entrpoint_cmd"
  echo "Second part: $entrpoint_args"

  echo "docker run --rm --env-file \"$ENV_FILE\" $RUN_ARGS --entrypoint \"$entrpoint_cmd\" \"$IMAGE_NAME:$IMAGE_TAG\" $entrpoint_args $COMMAND"
  docker run --rm --env-file "$ENV_FILE" $RUN_ARGS --entrypoint "$entrpoint_cmd" "$IMAGE_NAME:$IMAGE_TAG" $entrpoint_args "$COMMAND"

fi

