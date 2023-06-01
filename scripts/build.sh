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
if [ "$IS_TESTING" = "true" ]; then
  IMAGE_TAG="testing"
else
  IMAGE_TAG="latest"
fi

echo "Building image..."
docker build $BUILD_ARGS --file "$DOCKERFILE" "$STAGE_PART" -t "$IMAGE_NAME:$IMAGE_TAG" "$BUILD_CONTEXT" || exit 1

echo "Post-build image list:"
docker images
echo "Cleanup unused Docker resources.."
# Remove unused resources that would otherwise persist between builds by virtue of GH dependency caching
docker rmi -f $(docker images | awk '$2 != "latest" && $2 != "testing" {print $3}') >/dev/null 2>&1 || exit 0
docker system prune -f
echo "Image list after cleanup:"
docker images
echo "List of containers:"
docker ps -a
echo "Done."
