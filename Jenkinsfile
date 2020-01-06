pipeline {
  agent any
  stages {
    stage('Test') {
      parallel {
        stage('DMD') {
          steps {
            sh 'dmd test --compiler=dmd'
          }
        }

        stage('GDC') {
          steps {
            sh 'dmd test --compiler=gdc'
          }
        }

        stage('LDC') {
          steps {
            sh 'dmd test --compiler=ldc'
          }
        }

      }
    }

  }
}