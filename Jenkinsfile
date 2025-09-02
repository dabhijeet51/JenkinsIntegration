pipeline {
    agent any

    environment {
        PARAM1      = ""
        browser     = "chrome-headless"
        ENVIRONMENT = "pie1"
        screenshot  = "true"
        TASK        = "misc:run"
        reruns      = "3"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Python') {
            steps {
                sh '''
                    echo "Checking Python version..."
                    if command -v python3 >/dev/null 2>&1; then
                        echo "Python 3 is available."
                    elif command -v python >/dev/null 2>&1; then
                        echo "Using default python (likely 2.7)."
                    else
                        echo "ERROR: No python found on this node!"
                        exit 1
                    fi
                '''
            }
        }

        stage('Install Dependencies & Run Tests') {
            steps {
                sh '''
                    chmod +x script/run_automated_tests.sh
                    ENVIRONMENT="${ENVIRONMENT}" \
                    BROWSER="${browser}" \
                    PARAM1="${PARAM1}" \
                    SCREENSHOT="${screenshot}" \
                    TASK="${TASK}" \
                    RERUNS="${reruns}" \
                    bash -l script/run_automated_tests.sh
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'reports/**', fingerprint: true
        junit 'reports/results.xml'
        publishHTML([[
            reportDir: 'reports',
            reportFiles: 'report.html',
            reportName: 'HTML Report'
        ]])
    }
}
