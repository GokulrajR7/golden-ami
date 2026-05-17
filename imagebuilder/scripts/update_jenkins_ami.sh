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

def jenkins = Jenkins.instance

jenkins.clouds.each { cloud ->

    if (cloud instanceof AmazonEC2Cloud) {

        def newTemplates = []

        cloud.templates.each { template ->

            println("Template Labels: " + template.labelString)

            if (template.labelString.contains("gami2023")) {

                println("Updating Template: " + template.description)

                println("Old AMI: " + template.ami)

                def newTemplate = template.clone()

                newTemplate.ami = latestAmi

                println("Updated AMI: " + newTemplate.ami)

                newTemplates.add(newTemplate)

            } else {

                newTemplates.add(template)
            }
        }

        cloud.templates.clear()
        cloud.templates.addAll(newTemplates)
    }
}

jenkins.save()

println("Jenkins cloud AMI updated successfully.")

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
