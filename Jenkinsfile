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
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker push ${REACT_IMAGE}:${BUILD_NUMBER}
                    docker push ${API_IMAGE}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Package & Push Helm Charts') {
            steps {
                sh '''
                    echo "Packaging Helm chart..."
                    cd /home/ubuntu/reactui-api
                    sudo helm package helm-ui-api --version ${BUILD_NUMBER}

                    echo "Pushing Helm chart to JFrog..."
                    curl -u "$JFROG_USER:$JFROG_PASSWORD" -T helm-ui-api-${BUILD_NUMBER}.tgz ${HELM_REPO_URL}/helm-ui-api-${BUILD_NUMBER}.tgz
                '''
            }
        }

        stage('Deploy to EKS via Helm') {
            agent {
                label 'eks-instance'
            }
            steps {
                script {
                    // Configure AWS CLI to interact with your EKS cluster
                    sh '''
                        echo "Configuring AWS CLI and EKS..."
                        aws eks --region ${AWS_REGION} update-kubeconfig --name ${EKS_CLUSTER_NAME}
                    '''
                    
                    // Remove any existing Helm release
                    sh '''
                        echo "Checking if Helm release exists and deleting it if present..."
                        helm list --namespace default | grep ${HELM_RELEASE_NAME} && helm uninstall ${HELM_RELEASE_NAME} --namespace default || echo "No existing Helm release found."
                    '''
                    
                    // Use Helm to install the new package to the EKS cluster
                    sh '''
                        echo "Adding Helm chart repo..."
                        helm repo add reactui-api ${HELM_REPO_URL} --username ${JFROG_USER} --password ${JFROG_PASSWORD}
                        helm repo update

                        echo "Installing Helm release..."
                        helm install reactui-api-release reactui-api/helm-ui-api --version ${BUILD_NUMBER} --namespace default \
                          --set ui.image.tag=${BUILD_NUMBER} \
                          --set api.image.tag=${BUILD_NUMBER}
                    '''
                }
            }
        }
    }
}
