#!/bin/bash

set -e

AMI_ID=$1
JENKINS_URL=$2
JENKINS_USER=$3
JENKINS_TOKEN=$4

echo "Fetching Jenkins crumb..."

curl -s -c cookies.txt \
  --user "${JENKINS_USER}:${JENKINS_TOKEN}" \
  "${JENKINS_URL}/crumbIssuer/api/json" > crumb.json

CRUMB=$(jq -r '.crumb' crumb.json)

echo "Crumb fetched successfully."

cat > update_ami.groovy <<EOF

import jenkins.model.*
import hudson.plugins.ec2.*

def latestAmi = "${AMI_ID}"

def instance = Jenkins.instance

def cloud = instance.clouds.getByName("gami2023")

if (cloud == null) {

    println("Cloud not found")
    return
}

println("Latest AMI: ${latestAmi}")

cloud.templates.each { template ->

    if (template.description == "goldenami") {

        println("Updating template AMI...")

        println("Old AMI: ${template.ami}")

        template.ami = latestAmi

        println("Updated AMI to: ${latestAmi}")
    }
}

instance.save()

println("Jenkins cloud configuration saved")

EOF

echo "Updating Jenkins cloud AMI..."

curl -s -L -X POST \
  --user "${JENKINS_USER}:${JENKINS_TOKEN}" \
  --cookie cookies.txt \
  --cookie-jar cookies.txt \
  -H "Jenkins-Crumb:${CRUMB}" \
  --data-urlencode "script=$(cat update_ami.groovy)" \
  "${JENKINS_URL}/scriptText"

echo "AMI update request completed."
