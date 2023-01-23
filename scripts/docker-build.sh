#!/bin/sh

set -e

BUILD_CONTEXT="$1"
BUILD_ARGS="$2"
IMAGE_NAME="$3"
MULTI_STAGE="$4"
TESTING_TAG="$5"
PRODUCTION_STAGE="$6"
TESTING_STAGE="$7"


# Removed remote tag locally
if [ "$MULTI_STAGE" != "false" ]
then
	echo "Building image..."
  docker build $BUILD_ARGS --target "$PRODUCTION_STAGE" -t "$IMAGE_NAME:latest" "$BUILD_CONTEXT" || exit 1
  echo "Building test image..."
  echo "docker build $BUILD_ARGS --target \"$TESTING_STAGE\" -t \"$IMAGE_NAME:$TESTING_TAG\" \"$BUILD_CONTEXT\""
  docker build $BUILD_ARGS --target "$TESTING_STAGE" -t "$IMAGE_NAME:$TESTING_TAG" "$BUILD_CONTEXT" || exit 1
else
  echo "Building image..."
  docker build $BUILD_ARGS -t "$IMAGE_NAME:latest" "$BUILD_CONTEXT" || exit 1
fi
echo "Post-build image list:"
docker images
echo "Cleanup unused Docker resources.."
# Remove unused resources that would otherwise persist between builds by virtue of GH dependency caching
docker system prune -f
echo "Image list after cleanup:"
docker images
echo "List of containers:"
docker ps -a
echo "Done."
