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
                    def ps1Files = findFiles(glob: '*.ps1')
                    if (ps1Files.length == 0) {
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
