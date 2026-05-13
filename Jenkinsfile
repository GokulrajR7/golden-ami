pipeline {
  agent any

  environment {
    REGION = "ap-south-1"
  }

  stages {

    // ==========================================
    // Checkout Repository
    // ==========================================
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    // ==========================================
    // Check YAML Changes
    // ==========================================
    stage('Check YAML Changes') {

      steps {

        script {

          def changed = sh(
            script: """
              git diff --name-only HEAD~1 HEAD |
              grep '\\.yaml$\\|\\.yml$' || true
            """,
            returnStdout: true
          ).trim()

          if (changed) {
            env.BUILD_AMI = "true"
          } else {
            env.BUILD_AMI = "false"
          }

          echo "YAML Changed: ${env.BUILD_AMI}"
        }
      }
    }

    // ==========================================
    // Trigger Image Builder
    // ==========================================
    stage('Build Golden AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh 'chmod +x build_ami.sh'

        sh './build_ami.sh'
      }
    }

    // ==========================================
    // Show Latest AMI
    // ==========================================
    stage('Print Latest AMI ID') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh 'cat output/ami.txt'
      }
    }
  }
}
