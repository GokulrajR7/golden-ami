#!/bin/bash

set -e

AMI_ID=$1
JENKINS_URL=$2
JENKINS_USER=$3
JENKINS_TOKEN=$4

echo "Fetching Jenkins crumb..."

CRUMB=$(curl -s \
  --user "${JENKINS_USER}:${JENKINS_TOKEN}" \
  "${JENKINS_URL}/crumbIssuer/api/json" \
  | jq -r '.crumb')

echo "Crumb fetched successfully."

cat > update_ami.groovy <<EOF

import jenkins.model.*
import hudson.plugins.ec2.*

def latestAmi = "${AMI_ID}"

def jenkins = Jenkins.instance

jenkins.clouds.each { cloud ->

    if (cloud instanceof AmazonEC2Cloud) {

        cloud.templates.each { template ->

            println("Template Labels: " + template.labelString)

            if (template.labelString.contains("gami2023")) {

                println("Updating Template: " + template.description)

                println("Old AMI: " + template.ami)

                template.ami = latestAmi

                println("Updated AMI: " + template.ami)
            }
        }
    }
}

jenkins.save()

println("Jenkins cloud AMI updated successfully.")

EOF

echo "Updating Jenkins cloud AMI..."

curl -s -X POST \
  --user "${JENKINS_USER}:${JENKINS_TOKEN}" \
  -H "Jenkins-Crumb:${CRUMB}" \
  --data-urlencode "script=$(cat update_ami.groovy)" \
  "${JENKINS_URL}/scriptText"

echo "AMI update request completed."
