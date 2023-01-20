#!/bin/sh
BUILD_CONTEXT="$1"
BUILD_ARGS="$2"
IMAGE_NAME="$3"
PRODUCTION_TAG="$4"
MULTI_STAGE="$5"
TESTING_TAG="$6"
PRODUCTION_STAGE="$7"
TESTING_STAGE="$8"


if [ "$MULTI_STAGE" != "false" ]
then
	echo "Building multi-stages images."
  docker build --build-arg $BUILD_ARGS --target "$PRODUCTION_STAGE" -t "$IMAGE_NAME:$PRODUCTION_TAG" "$BUILD_CONTEXT" && docker build --build-arg $BUILD_ARGS --target "$TESTING_STAGE" -t "$IMAGE_NAME:$TESTING_TAG" "$BUILD_CONTEXT"
else
  echo "Building single-stage image."
  docker build --build-arg $BUILD_ARGS -t "$IMAGE_NAME:$PRODUCTION_TAG" "$BUILD_CONTEXT"
fi

echo "Done."
