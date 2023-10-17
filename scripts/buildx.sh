#!/bin/sh

set -e

BUILD_CONTEXT="$1"
DOCKERFILE="$2"
BUILD_ARGS="$3"
IMAGE_NAME="$4"
STAGES="$5"

echo "Images before build:"
docker images


if [ -z "$STAGES" ]; then
  echo "Building $IMAGE_NAME image..."
  docker buildx build $BUILD_ARGS --file "$DOCKERFILE" -t "$IMAGE_NAME:dist" "$BUILD_CONTEXT" --cache-from "type=local,src=/tmp/.build-cache-$IMAGE_NAME" --cache-to "type=local,dest=/tmp/.build-cache-new-$IMAGE_NAME,mode=max" --load || exit 1
else
  echo "$STAGES" | tr ',' '\n' | while IFS= read -r value; do
    trimmed_stage=$(echo "$value" | xargs)

    echo "Building stage $trimmed_stage of $IMAGE_NAME image..."
    docker buildx build $BUILD_ARGS --file "$DOCKERFILE" --target $trimmed_stage -t "$IMAGE_NAME:$trimmed_stage" "$BUILD_CONTEXT" --cache-from "type=local,src=/tmp/.build-cache-$IMAGE_NAME" --cache-to "type=local,dest=/tmp/.build-cache-new-$IMAGE_NAME,mode=max" --load || exit 1
  done
fi

echo "Images after build:"
docker images
