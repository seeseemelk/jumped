pipeline {
  agent any
  stages {
    stage('Test') {
      parallel {
        stage('DMD') {
          steps {
            sh './test.sh --compiler=ldc'
          }
        }

        stage('LDC') {
          steps {
            sh './test.sh --compiler=ldc'
          }
        }

      }
    }

  }
}
