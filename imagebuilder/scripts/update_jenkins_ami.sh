#!/bin/bash

set -e

AMI_ID=$1
JENKINS_URL=$2
JENKINS_USER=$3
JENKINS_TOKEN=$4

cat > update_ami.groovy <<EOF

import jenkins.model.*
import hudson.plugins.ec2.*

def latestAmi = "${AMI_ID}"

def jenkins = Jenkins.instance

jenkins.clouds.each { cloud ->

    if (cloud instanceof AmazonEC2Cloud) {

        cloud.templates.each { template ->

            println("Old AMI: " + template.ami)

            template.ami = latestAmi

            println("Updated AMI: " + template.ami)
        }
    }
}

jenkins.save()

println("Jenkins cloud AMI updated successfully.")

EOF

curl -X POST \
  --user "${JENKINS_USER}:${JENKINS_TOKEN}" \
  --data-urlencode "script=$(cat update_ami.groovy)" \
  ${JENKINS_URL}/scriptText
