pipeline {
    agent {
        label 'docker'
    }
    environment {
        DOCKERHUB_CREDS = credentials('docker')
        DOCKERHUB_USER = "${DOCKERHUB_CREDS_USR}"
        DOCKER_USER = "${DOCKERHUB_CREDS_USR}"
        DOCKER_PASS = "${DOCKERHUB_CREDS_PSW}"
        REACT_IMAGE = "${DOCKERHUB_USER}/ui"
        API_IMAGE = "${DOCKERHUB_USER}/api"

        JFROG_USER = 'anushahp16@gmail.com'
        JFROG_PASSWORD = credentials('jfrog_token') // Secret text credential
        HELM_REPO_URL = 'https://trial8mol56.jfrog.io/artifactory/reactui-api-helm'

        AWS_REGION = 'ap-south-1'  // Adjust with your AWS region
        EKS_CLUSTER_NAME = 'my-cluster'  // Replace with your EKS cluster name
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/DevopsAHP/assignment.git'
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    echo "Building React UI image..."
                    docker build -t ${REACT_IMAGE}:${BUILD_NUMBER} ./react-ui

                    echo "Building Flask API image..."
                    docker build -t ${API_IMAGE}:${BUILD_NUMBER} ./api-server-flask
                '''
            }
        }

        stage('Push Docker Images') {
            steps {
                sh '''
                    echo "Pushing Docker images..."
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --
