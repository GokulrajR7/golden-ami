pipeline {

    agent {
        label 'windows-agent'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {

        REGION = "ap-south-1"

        COMPONENT_NAME = "jenkins-al2023-component"

        RECIPE_NAME = "jenkins-al2023-recipe"

        VERSION = "1.0.${BUILD_NUMBER}"

        SCRIPT_BUCKET = "golden-ami-scripts-gokul"

        PIPELINE_ARN = "arn:aws:imagebuilder:ap-south-1:272916400173:image-pipeline/testing-pipeline"

        INFRA_ARN = "arn:aws:imagebuilder:ap-south-1:272916400173:infrastructure-configuration/onestrata-prereq-infra"

        PARENT_IMAGE = "arn:aws:imagebuilder:ap-south-1:aws:image/amazon-linux-2023-x86/2023.12.15"
    }

    stages {

        // =====================================================
        // Checkout Source
        // =====================================================

        stage('Checkout') {

            steps {

                echo "Checking out source code..."

                checkout scm

                sh '''
                    echo "Workspace:"
                    pwd

                    echo "Repository Structure:"
                    find . -type f
                '''
            }
        }

        // =====================================================
        // Validate AWS Access
        // =====================================================

        stage('Validate AWS') {

            steps {

                sh '''
                    set -e

                    echo "Validating AWS Access..."

                    aws sts get-caller-identity
                '''
            }
        }

        // =====================================================
        // Validate Required Files
        // =====================================================

        stage('Validate Files') {

            steps {

                sh '''
                    set -e

                    test -f imagebuilder/scripts/install.sh

                    test -f imagebuilder/components/jenkins-al2023-component.yaml

                    test -f imagebuilder/scripts/wait_for_ami.sh

                    test -f imagebuilder/scripts/fetch_ami.sh

                    test -f imagebuilder/scripts/update_jenkins_ami.sh

                    echo "All required files exist."
                '''
            }
        }

        // =====================================================
        // Upload Shell Script to S3
        // =====================================================

        stage('Upload Script') {

            steps {

                sh '''
                    set -e

                    echo "Current Workspace:"
                    pwd

                    echo "Listing imagebuilder/scripts directory:"
                    ls -l imagebuilder/scripts/

                    SCRIPT_PATH="${WORKSPACE}/imagebuilder/scripts/install.sh"

                    echo "Validating script exists..."

                    if [ ! -f "$SCRIPT_PATH" ]; then
                        echo "ERROR: install.sh not found!"
                        exit 1
                    fi

                    chmod +x "$SCRIPT_PATH"

                    echo "Removing old install.sh from S3 if exists..."

                    aws s3 rm \
                        "s3://${SCRIPT_BUCKET}/install.sh" \
                        --region "${REGION}" || true

                    echo "Uploading latest install.sh to S3..."

                    aws s3 cp \
                        "$SCRIPT_PATH" \
                        "s3://${SCRIPT_BUCKET}/install.sh" \
                        --region "${REGION}"

                    echo "Verifying uploaded file..."

                    aws s3 ls \
                        "s3://${SCRIPT_BUCKET}/install.sh" \
                        --region "${REGION}"

                    echo "Upload completed successfully."
                '''
            }
        }

        // =====================================================
        // Create Image Builder Component
        // =====================================================

        stage('Create Component') {

            steps {

                script {

                    env.COMPONENT_ARN = sh(

                        script: """
                            aws imagebuilder create-component \
                            --name ${COMPONENT_NAME} \
                            --semantic-version ${VERSION} \
                            --platform Linux \
                            --data file://imagebuilder/components/jenkins-al2023-component.yaml \
                            --region ${REGION} \
                            --query 'componentBuildVersionArn' \
                            --output text
                        """,

                        returnStdout: true

                    ).trim()

                    echo "Created Component ARN:"
                    echo "${env.COMPONENT_ARN}"
                }
            }
        }

        // =====================================================
        // Create Image Recipe
        // =====================================================

        stage('Create Recipe') {

            steps {

                script {

                    env.RECIPE_ARN = sh(

                        script: """
                            aws imagebuilder create-image-recipe \
                            --name ${RECIPE_NAME} \
                            --semantic-version ${VERSION} \
                            --components componentArn=${COMPONENT_ARN} \
                            --parent-image ${PARENT_IMAGE} \
                            --block-device-mappings '[{"deviceName":"/dev/xvda","ebs":{"volumeSize":20}}]' \
                            --region ${REGION} \
                            --query 'imageRecipeArn' \
                            --output text
                        """,

                        returnStdout: true

                    ).trim()

                    echo "Created Recipe ARN:"
                    echo "${env.RECIPE_ARN}"
                }
            }
        }

        // =====================================================
        // Update Existing Pipeline
        // =====================================================

        stage('Update Pipeline') {

            steps {

                sh '''
                    set -e

                    echo "Updating Image Pipeline..."

                    aws imagebuilder update-image-pipeline \
                    --image-pipeline-arn ${PIPELINE_ARN} \
                    --image-recipe-arn ${RECIPE_ARN} \
                    --infrastructure-configuration-arn ${INFRA_ARN} \
                    --region ${REGION}
                '''
            }
        }

        // =====================================================
        // Start AMI Build
        // =====================================================

        stage('Start AMI Build') {

            steps {

                script {

                    env.IMAGE_BUILD_VERSION_ARN = sh(

                        script: """
                            aws imagebuilder start-image-pipeline-execution \
                            --image-pipeline-arn ${PIPELINE_ARN} \
                            --region ${REGION} \
                            --query 'imageBuildVersionArn' \
                            --output text
                        """,

                        returnStdout: true

                    ).trim()

                    echo "Started Image Build:"
                    echo "${env.IMAGE_BUILD_VERSION_ARN}"
                }
            }
        }

        // =====================================================
        // Wait For AMI
        // =====================================================

        stage('Wait For AMI') {

            steps {

                sh '''
                    chmod +x imagebuilder/scripts/wait_for_ami.sh

                    imagebuilder/scripts/wait_for_ami.sh \
                    ${IMAGE_BUILD_VERSION_ARN} \
                    ${REGION}
                '''
            }
        }

        // =====================================================
        // Fetch Latest AMI
        // =====================================================

        stage('Fetch Latest AMI') {

            steps {

                sh '''
                    chmod +x imagebuilder/scripts/fetch_ami.sh

                    imagebuilder/scripts/fetch_ami.sh \
                    ${IMAGE_BUILD_VERSION_ARN} \
                    ${REGION}

                    cat output/latest_ami.txt
                '''

                script {

                    env.LATEST_AMI_ID = sh(
                        script: 'cat output/latest_ami.txt',
                        returnStdout: true
                    ).trim()

                    echo "================================="
                    echo "LATEST CREATED AMI:"
                    echo "${env.LATEST_AMI_ID}"
                    echo "================================="
                }
            }
        }

        // =====================================================
        // Update Jenkins Cloud AMI
        // =====================================================

        stage('Update Jenkins Cloud AMI') {

            agent {
                label 'built-in'
            }

            steps {

                withCredentials([usernamePassword(
                    credentialsId: 'jenkins-api-creds-gokul',
                    usernameVariable: 'JENKINS_USER',
                    passwordVariable: 'JENKINS_TOKEN'
                )]) {

                    sh '''
                        chmod +x imagebuilder/scripts/update_jenkins_ami.sh

                        imagebuilder/scripts/update_jenkins_ami.sh \
                        ${LATEST_AMI_ID} \
                        http://localhost:8080 \
                        ${JENKINS_USER} \
                        ${JENKINS_TOKEN}
                    '''
                }
            }
        }
    }

    // =====================================================
    // Post Actions
    // =====================================================

    post {

        success {

            echo "Golden AMI pipeline completed successfully."
        }

        failure {

            echo "Pipeline failed."
        }

        always {

            archiveArtifacts(
                artifacts: 'output/**/*',
                allowEmptyArchive: true
            )

            echo "Pipeline execution completed."
        }
    }
}
