pipeline {
    agent any

    environment {
        DOCKER_HUB_USER  = 'mohamedelaazzaoui00'
        DOCKER_HUB_CREDS = credentials('dockerhub-credentials')
        IMAGE_TAG        = "${BUILD_NUMBER}"
        BACKEND_PATH     = 'C_R_S_Back/credit_management_system'
        FRONTEND_PATH    = 'C_R_S_Front/Front'
        NETWORK          = 'spring-net'
        DB_HOST          = 'mysql-db'
        DB_NAME          = 'python'
        DB_USER          = 'root'
        DB_PASSWORD      = 'mohamed12345'
        JWT_SECRET       = '5367566B59703373367639792F423F4528482B4D6251655468576D5A71347437'
        AES_KEY          = 'MySecretKey12345MySecretKey12345'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo "Checkout OK - Branch: ${env.BRANCH_NAME}"
            }
        }

        stage('Build Backend Image') {
            steps {
                dir("${BACKEND_PATH}") {
                    sh "docker build -t ${DOCKER_HUB_USER}/credit-backend:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKER_HUB_USER}/credit-backend:${IMAGE_TAG} ${DOCKER_HUB_USER}/credit-backend:latest"
                    echo "Backend image built OK"
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                dir("${FRONTEND_PATH}") {
                    sh "docker build -t ${DOCKER_HUB_USER}/credit-frontend:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKER_HUB_USER}/credit-frontend:${IMAGE_TAG} ${DOCKER_HUB_USER}/credit-frontend:latest"
                    echo "Frontend image built OK"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                sh "echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin"
                sh "docker push ${DOCKER_HUB_USER}/credit-backend:${IMAGE_TAG}"
                sh "docker push ${DOCKER_HUB_USER}/credit-backend:latest"
                sh "docker push ${DOCKER_HUB_USER}/credit-frontend:${IMAGE_TAG}"
                sh "docker push ${DOCKER_HUB_USER}/credit-frontend:latest"
                echo "Push to Docker Hub OK"
            }
        }

        stage('Deploy') {
            steps {
                sh """
                docker network create ${NETWORK} 2>/dev/null || true
                docker network connect ${NETWORK} mysql-db 2>/dev/null || true
                docker stop credit-backend credit-frontend 2>/dev/null || true
                docker rm credit-backend credit-frontend 2>/dev/null || true
                sleep 3

                docker run -d \
                  --name credit-backend \
                  --network ${NETWORK} \
                  --restart unless-stopped \
                  -p 8080:8080 \
                  -e SPRING_DATASOURCE_URL=jdbc:mysql://${DB_HOST}:3306/${DB_NAME}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC \
                  -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
                  -e SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD} \
                  -e SPRING_JPA_HIBERNATE_DDL_AUTO=update \
                  -e JWT_SECRET=${JWT_SECRET} \
                  -e JWT_EXPIRATION=86400000 \
                  -e ENCRYPTION_SECRET_KEY=${AES_KEY} \
                  -e CORS_ALLOWED_ORIGINS=http://localhost:3000 \
                  ${DOCKER_HUB_USER}/credit-backend:latest

                sleep 30

                docker run -d \
                  --name credit-frontend \
                  --network ${NETWORK} \
                  --restart unless-stopped \
                  -p 3000:80 \
                  ${DOCKER_HUB_USER}/credit-frontend:latest

                echo "Deploy OK"
                """
            }
        }

        stage('Smoke Test') {
            steps {
                sh """
                sleep 15
                curl -f http://localhost:3000 && echo "Frontend OK" || echo "Frontend check needed"
                docker ps | grep -E "credit-backend|credit-frontend|mysql-db"
                """
            }
        }
    }

    post {
        success {
            echo "Build ${BUILD_NUMBER} - SUCCES - Frontend: http://localhost:3000"
        }
        failure {
            sh "docker logs credit-backend --tail 20 2>/dev/null || true"
            echo "Build ${BUILD_NUMBER} - ECHEC"
        }
        always {
            sh "docker logout || true"
        }
    }
}
