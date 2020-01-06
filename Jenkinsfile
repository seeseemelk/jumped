pipeline {
  agent any
  stages {
    stage('Test') {
      parallel {
        stage('DMD') {
          steps {
            sh 'dub test --compiler=dmd'
          }
        }

        stage('LDC') {
          steps {
            sh 'dub test --compiler=ldc'
          }
        }

      }
    }

  }
}