pipeline {

    agent {
        label 'gami2023'
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
                checkout scm
            }
        }

        // =====================================================
        // Upload Shell Script to S3
        // =====================================================

        stage('Upload Script') {

            steps {

                sh """
                    aws s3 cp \
                    imagebuilder/scripts/install.sh \
                    s3://${SCRIPT_BUCKET}/install.sh \
                    --region ${REGION}
                """
            }
        }

        // =====================================================
        // Create Image Builder Component
        // =====================================================

        stage('Create Component') {

            steps {

                sh """
                    aws imagebuilder create-component \
                    --name ${COMPONENT_NAME} \
                    --semantic-version ${VERSION} \
                    --platform Linux \
                    --data file://imagebuilder/components/jenkins-al2023-component.yaml \
                    --region ${REGION}
                """
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
                            --query "componentVersionList[?name=='${COMPONENT_NAME}'] | [-1].arn" \
                            --output text
                        """,

                        returnStdout: true

                    ).trim()

                    echo "Component ARN: ${env.COMPONENT_ARN}"
                }
            }
        }

        // =====================================================
        // Create Recipe
        // =====================================================

        stage('Create Recipe') {

            steps {

                sh """
                    aws imagebuilder create-image-recipe \
                    --name ${RECIPE_NAME} \
                    --semantic-version ${VERSION} \
                    --components componentArn=${COMPONENT_ARN} \
                    --parent-image ${PARENT_IMAGE} \
                    --block-device-mappings '[{"deviceName":"/dev/xvda","ebs":{"volumeSize":20}}]' \
                    --region ${REGION}
                """
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
                            --query "imageRecipeSummaryList[?name=='${RECIPE_NAME}'] | [-1].arn" \
                            --output text
                        """,

                        returnStdout: true

                    ).trim()

                    echo "Recipe ARN: ${env.RECIPE_ARN}"
                }
            }
        }

        // =====================================================
        // Update Existing Pipeline
        // =====================================================

        stage('Update Pipeline') {

            steps {

                sh """
                    aws imagebuilder update-image-pipeline \
                    --image-pipeline-arn ${PIPELINE_ARN} \
                    --image-recipe-arn ${RECIPE_ARN} \
                    --infrastructure-configuration-arn ${INFRA_ARN} \
                    --region ${REGION}
                """
            }
        }

        // =====================================================
        // Start AMI Build
        // =====================================================

        stage('Start AMI Build') {

            steps {

                sh """
                    aws imagebuilder start-image-pipeline-execution \
                    --image-pipeline-arn ${PIPELINE_ARN} \
                    --region ${REGION}
                """
            }
        }
    }

    post {

        success {

            echo "Golden AMI build triggered successfully."
        }

        failure {

            echo "Pipeline failed."
        }
    }
}
