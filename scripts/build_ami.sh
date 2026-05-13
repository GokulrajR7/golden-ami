#!/bin/bash

set -e

# ==========================================
# Variables
# ==========================================
REGION="ap-south-1"

PIPELINE_ARN="arn:aws:imagebuilder:ap-south-1:272916400173:image-pipeline/jenkins-agent-al2023-pipeline"

OUTPUT_DIR="output"

mkdir -p $OUTPUT_DIR

echo "🚀 Triggering EC2 Image Builder..."

# ==========================================
# Trigger Pipeline
# ==========================================
BUILD_ARN=$(aws imagebuilder start-image-pipeline-execution \
  --image-pipeline-arn $PIPELINE_ARN \
  --region $REGION \
  --query 'imageBuildVersionArn' \
  --output text)

echo "Pipeline started:"
echo "$BUILD_ARN"

# ==========================================
# Wait for Build
# ==========================================
echo "⏳ Waiting for AMI creation..."

sleep 300

# ==========================================
# Fetch Latest AMI ID
# ==========================================
AMI_ID=$(aws ec2 describe-images \
  --owners self \
  --region $REGION \
  --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
  --output text)

echo "✅ Latest AMI:"
echo "$AMI_ID"

# ==========================================
# Save AMI ID
# ==========================================
echo "$AMI_ID" > $OUTPUT_DIR/ami.txt

echo "AMI saved to output/ami.txt"
