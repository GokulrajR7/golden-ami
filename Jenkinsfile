pipeline {

    agent {
        label 'gami2023'
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

                    chmod +x imagebuilder/scripts/install.sh

                    echo "Uploading install.sh to S3..."

                    aws s3 cp \
                    imagebuilder/scripts/install.sh \
                    s3://${SCRIPT_BUCKET}/install.sh \
                    --region ${REGION}
                '''
            }
        }

        // =====================================================
        // Create Image Builder Component
        // =====================================================

        stage('Create Component') {

            steps {

                sh '''
                    set -e

                    echo "Creating Image Builder Component..."

                    aws imagebuilder create-component \
                    --name ${COMPONENT_NAME} \
                    --semantic-version ${VERSION} \
                    --platform Linux \
                    --data file://imagebuilder/components/jenkins-al2023-component.yaml \
                    --region ${REGION}
                '''
            }
        }

        // =====================================================
        // Fetch Latest Component ARN
        // =====================================================

        stage('Fetch Component ARN') {

            steps {

                script {

                    env.COMPONENT_ARN = sh(

                        script: """
                            aws imagebuilder list-components \
                            --owner Self \
                            --region ${REGION} \
                            --query "sort_by(componentVersionList,&dateCreated)[-1].arn" \
                            --output text
                        """,

                        returnStdout: true

                    ).trim()

                    echo "Latest Component ARN:"
                    echo "${env.COMPONENT_ARN}"
                }
            }
        }

        // =====================================================
        // Create Image Recipe
        // =====================================================

        stage('Create Recipe') {

            steps {

                sh '''
                    set -e

                    echo "Creating Image Recipe..."

                    aws imagebuilder create-image-recipe \
                    --name ${RECIPE_NAME} \
                    --semantic-version ${VERSION} \
                    --components componentArn=${COMPONENT_ARN} \
                    --parent-image ${PARENT_IMAGE} \
                    --block-device-mappings '[{"deviceName":"/dev/xvda","ebs":{"volumeSize":20}}]' \
                    --region ${REGION}
                '''
            }
        }

        // =====================================================
        // Fetch Recipe ARN
        // =====================================================

        stage('Fetch Recipe ARN') {

            steps {

                script {

                    env.RECIPE_ARN = sh(

                        script: """
                            aws imagebuilder list-image-recipes \
                            --region ${REGION} \
                            --query "sort_by(imageRecipeSummaryList,&dateCreated)[-1].arn" \
                            --output text
                        """,

                        returnStdout: true

                    ).trim()

                    echo "Latest Recipe ARN:"
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

                sh '''
                    set -e

                    echo "Starting AMI Build..."

                    aws imagebuilder start-image-pipeline-execution \
                    --image-pipeline-arn ${PIPELINE_ARN} \
                    --region ${REGION}
                '''
            }
        }
    }

    // =====================================================
    // Post Actions
    // =====================================================

    post {

        success {

            echo "Golden AMI build triggered successfully."
        }

        failure {

            echo "Pipeline failed."
        }

        always {

            echo "Pipeline execution completed."
        }
    }
}
