#!/bin/bash

set -e

IMAGE_BUILD_VERSION_ARN=$1
REGION=$2

echo "Waiting for AMI build completion..."

while true
do

    STATUS=$(aws imagebuilder get-image \
        --image-build-version-arn "$IMAGE_BUILD_VERSION_ARN" \
        --region "$REGION" \
        --query 'image.state.status' \
        --output text)

    echo "Current Status: $STATUS"

    if [ "$STATUS" = "AVAILABLE" ]; then
        echo "AMI build completed successfully."
        break
    fi

    if [ "$STATUS" = "FAILED" ]; then
        echo "AMI build failed."
        exit 1
    fi

    sleep 60

done
