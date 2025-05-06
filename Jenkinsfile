pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        DOCKERHUB_USER = 'ahp1609'
        REACT_IMAGE = "${DOCKERHUB_USER}/reactui"
        API_IMAGE = "${DOCKERHUB_USER}/api"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-username/your-repo.git'
            }
        }

        stage('Detect Changes') {
            steps {
                sh '''
                    echo "Detecting changes..."
                    git diff --name-only HEAD~1 > changed_files.txt
                    grep '^reactui/' changed_files.txt && echo "true" > build_react || echo "false" > build_react
                    grep '^api/' changed_files.txt && echo "true" > build_api || echo "false" > build_api
                '''
            }
        }

        stage('Build & Push React UI') {
            when {
                expression { return readFile('build_react').trim() == 'true' }
            }
            steps {
                sh '''
                    if ! command -v docker &> /dev/null; then
                        echo "Docker is not installed or not in PATH"
                        exit 1
                    fi

                    echo "Building and pushing React UI..."
                    docker build -t ${REACT_IMAGE}:${BUILD_NUMBER} ./reactui
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker push ${REACT_IMAGE}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Build & Push API') {
            when {
                expression { return readFile('build_api').trim() == 'true' }
            }
            steps {
                sh '''
                    if ! command -v docker &> /dev/null; then
                        echo "Docker is not installed or not in PATH"
                        exit 1
                    fi

                    echo "Building and pushing API..."
                    docker build -t ${API_IMAGE}:${BUILD_NUMBER} ./api
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker push ${API_IMAGE}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Deploy with Helm') {
            when {
                anyOf {
                    expression { return readFile('build_react').trim() == 'true' }
                    expression { return readFile('build_api').trim() == 'true' }
                }
            }
            agent { label 'helm-deployer' }  // Run this stage on a node with Helm + Kubeconfig
            environment {
                KUBECONFIG = credentials('kubeconfig') // Secret file on this specific node
            }
            steps {
                sh '''
                    if ! command -v helm &> /dev/null; then
                        echo "Helm is not installed or not in PATH"
                        exit 1
                    fi

                    echo "Running Helm deployment..."
                    helm upgrade --install myapp ./helm-chart \
                        --set reactui.image.tag=${BUILD_NUMBER} \
                        --set api.image.tag=${BUILD_NUMBER}
                '''
            }
        }
    }
}
