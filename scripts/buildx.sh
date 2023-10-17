#!/bin/sh

set -e

BUILD_CONTEXT="$1"
DOCKERFILE="$2"
BUILD_ARGS="$3"
IMAGE_NAME="$4"
STAGE="$5"
IS_TESTING="$6"

echo "Image before build:"
docker images


if [ -z "$STAGE" ]; then
  STAGE_PART=""
else
  STAGE_PART="--target $STAGE"
fi

# check if is_testing

if [ "$IS_TESTING" = "true" ] || [ "$STAGE" = "testing" ]; then
  IMAGE_TAG="testing"
else
  IMAGE_TAG="latest"
fi

echo "Building image..."
docker buildx build $BUILD_ARGS --file "$DOCKERFILE" $STAGE_PART -t "$IMAGE_NAME:$IMAGE_TAG" "$BUILD_CONTEXT" --cache-from "type=local,src=/tmp/.buildx-cache-$IMAGE_NAME" --cache-to "type=local,dest=/tmp/.buildx-cache-new-$IMAGE_NAME,mode=max" --load || exit 1

echo "Post-build image list:"
docker images
