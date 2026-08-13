pipeline {
  agent any

  environment {
    JENKINS_WORKSPACE = "${env.WORKSPACE}"
    GEM_HOME          = "${env.WORKSPACE}/.gems"
    COVERAGE          = 'true'
  }

  options {
    timestamps()
    skipStagesAfterUnstable()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(daysToKeepStr: '14', numToKeepStr: '20'))
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Setup Environment') {
      steps {
        sh '''
          zsh -l bin/ci init
        '''
      }
    }

    stage('Run tests') {
      steps {
        sh '''
          zsh -l bin/ci test
        '''
      }
    }
  }

  post {
    always {
      recordCoverage(
        tools: [[parser: 'LCOV', pattern: '**/coverage/lcov.info']],
        sourceCodeRetention: 'EVERY_BUILD'
      )
    }
    success {
      echo 'Tests passed'
    }
    unstable {
      echo 'Tests failed (unstable)'
    }
    failure {
      echo 'Pipeline failed'
    }
  }
}
