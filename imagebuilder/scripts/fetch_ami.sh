#!/bin/bash

set -e

IMAGE_BUILD_VERSION_ARN=$1
REGION=$2

AMI_ID=$(aws imagebuilder get-image \
    --image-build-version-arn "$IMAGE_BUILD_VERSION_ARN" \
    --region "$REGION" \
    --query 'image.outputResources.amis[0].image' \
    --output text)

echo "=================================="
echo "LATEST AMI ID: $AMI_ID"
echo "=================================="

mkdir -p output

echo "$AMI_ID" > output/latest_ami.txt
