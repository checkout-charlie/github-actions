#!/bin/sh

set -e

BUILD_CONTEXT="$1"
BUILD_ARGS="$2"
IMAGE_NAME="$3"
MULTI_STAGE="$4"
TESTING_TAG="$5"
PRODUCTION_STAGE="$6"
TESTING_STAGE="$7"
ADDITIONAL_TAG="$8"

if [ -z "$COMMIT_HASH" ]; then
  ADDITIONAL_TAG_COMMAND=""
else
  ADDITIONAL_TAG_COMMAND="-t $IMAGE_NAME:$ADDITIONAL_TAG"
fi


if [ "$MULTI_STAGE" != "false" ]
then
	echo "Building image..."
  docker build $BUILD_ARGS --target "$PRODUCTION_STAGE" -t "$IMAGE_NAME:$GITHUB_SHA" -t "$IMAGE_NAME:latest" $ADDITIONAL_TAG_COMMAND "$BUILD_CONTEXT" \
  && echo "Building test image..." \
  && docker build $BUILD_ARGS --target "$TESTING_STAGE" -t "$IMAGE_NAME:$TESTING_TAG" -t "$IMAGE_NAME:testing" "$BUILD_CONTEXT"
else
  echo "Building image..."
  echo "docker build --build-arg $BUILD_ARGS -t \"$IMAGE_NAME:$GITHUB_SHA\" $ADDITIONAL_TAG_COMMAND \"$BUILD_CONTEXT"
  docker build $BUILD_ARGS -t "$IMAGE_NAME:$GITHUB_SHA" $ADDITIONAL_TAG_COMMAND "$BUILD_CONTEXT"
fi

echo "Cleanup.."
echo "Deleting older images.."
echo "docker images | awk '{print $3}' | grep \"$IMAGE_NAME\" | grep -v \"$IMAGE_NAME:latest\|$IMAGE_NAME:testing\" | xargs docker rmi"
docker images | awk '{print $3}' | grep "$IMAGE_NAME" | grep -v "$IMAGE_NAME:latest\|$IMAGE_NAME:testing" | xargs docker rmi
echo "Purge unused layer cache.."
docker builder prune -a -f
echo "Done."
