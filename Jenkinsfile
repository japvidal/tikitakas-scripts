pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate Files') {
            steps {
                script {
                    def status = sh(script: 'ls *.ps1 >/dev/null 2>&1', returnStatus: true)
                    if (status != 0) {
                        error('No se encontraron scripts .ps1 en el repositorio')
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '*.ps1', allowEmptyArchive: false, fingerprint: true
        }
    }
}
