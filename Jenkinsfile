pipeline {
  agent none
  environment {
    PROJECT_NAME = 'ehealth'
    INSTANCE_TYPE = 'n1-highcpu-16'
    RD = "b${UUID.randomUUID().toString()}"
    RD_CROP = "b${RD.take(14)}"
    NAME = "${RD.take(5)}"
  }
  stages {
    stage('Prepare instance') {
      agent {
        kubernetes {
          label 'create-instance'
          defaultContainer 'jnlp'
        }
      }
      steps {
        container(name: 'gcloud', shell: '/bin/sh') {
          sh 'apk update && apk add curl bash'
          withCredentials([file(credentialsId: 'e7e3e6df-8ef5-4738-a4d5-f56bb02a8bb2', variable: 'KEYFILE')]) {
            sh 'gcloud auth activate-service-account jenkins-pool@ehealth-162117.iam.gserviceaccount.com --key-file=${KEYFILE} --project=ehealth-162117'
            sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/create_instance.sh -o create_instance.sh; bash ./create_instance.sh'
          }
          slackSend (color: '#8E24AA', message: "Instance for ${env.BUILD_TAG} created")
        }
      }
      post {
        success {
          slackSend (color: 'good', message: "Job - ${env.BUILD_TAG} STARTED (<${env.BUILD_URL}|Open>)")
        }
        failure {
          slackSend (color: 'danger', message: "Job - ${env.BUILD_TAG} FAILED to start (<${env.BUILD_URL}|Open>)")
        }
        aborted {
          slackSend (color: 'warning', message: "Job - ${env.BUILD_TAG} ABORTED before start (<${env.BUILD_URL}|Open>)")
        }
      }
    }
    stage('Test and build') {
      environment {
        MIX_ENV = 'test'
        DOCKER_NAMESPACE = 'edenlabllc'
        POSTGRES_VERSION = '9.6'
        POSTGRES_USER = 'postgres'
        POSTGRES_PASSWORD = 'postgres'
        POSTGRES_DB = 'postgres'
      }
      failFast true
      parallel {
        stage('Test') {
          environment {
            MIX_ENV = 'test'
            DOCKER_NAMESPACE = 'edenlabllc'
            POSTGRES_VERSION = '9.6'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label "ehealth-test-$NAME"
              defaultContainer 'jnlp'
              yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: test
spec:
  tolerations:
  - key: "ci"
    operator: "Equal"
    value: "$RD_CROP"
    effect: "NoSchedule"
  containers:
  - name: elixir
    image: elixir:1.8.1-alpine
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "32Mi"
        cpu: "10m"
      limits:
        memory: "4048Mi"
        cpu: "2000m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
    resources:
      requests:
        memory: "32Mi"
        cpu: "10m"
      limits:
        memory: "2048Mi"
        cpu: "1000m"
  - name: mongo
    image: mvertes/alpine-mongo:4.0.1-0
    ports:
    - containerPort: 27017
    tty: true
    resources:
      requests:
        memory: "32Mi"
        cpu: "10m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: redis
    image: redis:4-alpine3.9
    ports:
    - containerPort: 6379
    tty: true
  - name: kafkazookeeper
    image: johnnypark/kafka-zookeeper:2.1.0
    ports:
    - containerPort: 2181
    - containerPort: 9092
    env:
    - name: ADVERTISED_HOST
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    resources:
      requests:
        memory: "32Mi"
        cpu: "10m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  nodeSelector:
    node: "$RD_CROP"
"""
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
                sleep 15;
                psql -U postgres -c "create database ehealth";
                psql -U postgres -c "create database prm_dev";
                psql -U postgres -c "create database fraud_dev";
                psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'elixir', shell: '/bin/sh') {
              sh '''
                apk update && apk add --no-cache jq curl bash git ncurses-libs zlib ca-certificates openssl make build-base;
                mix local.hex --force;
                mix local.rebar --force;
                mix deps.get;
                mix deps.compile;
                curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/tests.sh -o tests.sh; bash ./tests.sh
              '''
            }
          }
        }
        stage('Build ehealth') {
          environment {
            APPS='[{"app":"ehealth","chart":"il","namespace":"il","deployment":"api","label":"api"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label "ehealth-build-$NAME"
              defaultContainer 'jnlp'
              yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "ci"
    operator: "Equal"
    value: "$RD_CROP"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: liubenokvlad/docker:18.09-alpine-elixir-1.8.1
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: DOCKER_HOST 
      value: tcp://localhost:2375 
    command:
    - cat
    tty: true
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "2048Mi"
        cpu: "1000m"
  - name: dind
    image: docker:18.09.2-dind
    securityContext: 
        privileged: true 
    ports:
    - containerPort: 2375
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "4048Mi"
        cpu: "8000m"
    volumeMounts: 
    - name: docker-graph-storage 
      mountPath: /var/lib/docker
  - name: mongo
    image: mvertes/alpine-mongo:4.0.1-0
    ports:
    - containerPort: 27017
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: redis
    image: redis:4-alpine3.9
    ports:
    - containerPort: 6379
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: kafkazookeeper
    image: johnnypark/kafka-zookeeper:2.1.0
    ports:
    - containerPort: 2181
    - containerPort: 9092
    env:
    - name: ADVERTISED_HOST
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
  nodeSelector:
    node: "$RD_CROP"
  volumes: 
    - name: docker-graph-storage 
      emptyDir: {}
"""
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for EHealth API-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          // post {
          //   always {
          //     container(name: 'docker', shell: '/bin/sh') {
          //       sh 'echo " ---- step: Remove docker image from host ---- ";'
          //       sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
          //     }
          //   }
          // }
        }
        stage('Build casher') {
          environment {
            APPS='[{"app":"casher","chart":"il","namespace":"il","deployment":"casher","label":"casher"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label "casher-build-$NAME"
              defaultContainer 'jnlp'
              yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "ci"
    operator: "Equal"
    value: "$RD_CROP"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: liubenokvlad/docker:18.09-alpine-elixir-1.8.1
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: DOCKER_HOST 
      value: tcp://localhost:2375 
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "2048Mi"
        cpu: "1000m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "2048Mi"
        cpu: "1000m"
  - name: dind
    image: docker:18.09.2-dind
    securityContext: 
        privileged: true 
    ports:
    - containerPort: 2375
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "4048Mi"
        cpu: "8000m"
    volumeMounts: 
    - name: docker-graph-storage 
      mountPath: /var/lib/docker
  - name: mongo
    image: mvertes/alpine-mongo:4.0.1-0
    ports:
    - containerPort: 27017
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: redis
    image: redis:4-alpine3.9
    ports:
    - containerPort: 6379
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: kafkazookeeper
    image: johnnypark/kafka-zookeeper:2.1.0
    ports:
    - containerPort: 2181
    - containerPort: 9092
    env:
    - name: ADVERTISED_HOST
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
  nodeSelector:
    node: "$RD_CROP"
  volumes: 
    - name: docker-graph-storage 
      emptyDir: {}
"""
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for Casher-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          // post {
          //   always {
          //     container(name: 'docker', shell: '/bin/sh') {
          //       sh 'echo " ---- step: Remove docker image from host ---- ";'
          //       sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
          //     }
          //   }
          // }
        }
        stage('Build graphql') {
          environment {
            APPS='[{"app":"graphql","chart":"il","namespace":"il","deployment":"graphql","label":"graphql"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label "graphql-build-$NAME"
              defaultContainer 'jnlp'
              yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "ci"
    operator: "Equal"
    value: "$RD_CROP"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: liubenokvlad/docker:18.09-alpine-elixir-1.8.1
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: DOCKER_HOST 
      value: tcp://localhost:2375 
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "2048Mi"
        cpu: "1000m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "2048Mi"
        cpu: "1000m"
  - name: dind
    image: docker:18.09.2-dind
    securityContext: 
        privileged: true 
    ports:
    - containerPort: 2375
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "2048Mi"
        cpu: "4000m"
    volumeMounts: 
    - name: docker-graph-storage 
      mountPath: /var/lib/docker
  - name: mongo
    image: mvertes/alpine-mongo:4.0.1-0
    ports:
    - containerPort: 27017
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: redis
    image: redis:4-alpine3.9
    ports:
    - containerPort: 6379
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: kafkazookeeper
    image: johnnypark/kafka-zookeeper:2.1.0
    ports:
    - containerPort: 2181
    - containerPort: 9092
    env:
    - name: ADVERTISED_HOST
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
  nodeSelector:
    node: "$RD_CROP"
  volumes: 
    - name: docker-graph-storage 
      emptyDir: {}
"""
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for GraphQL-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          // post {
          //   always {
          //     container(name: 'docker', shell: '/bin/sh') {
          //       sh 'echo " ---- step: Remove docker image from host ---- ";'
          //       sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
          //     }
          //   }
          // }
        }
        stage('Build merge-legal-entities-consumer') {
          environment {
            APPS='[{"app":"merge_legal_entities_consumer","chart":"il","namespace":"il","deployment":"merge-legal-entities-consumer","label":"merge-legal-entities-consumer"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label "merge-legal-entities-consumer-build-$NAME"
              defaultContainer 'jnlp'
              yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "ci"
    operator: "Equal"
    value: "$RD_CROP"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: liubenokvlad/docker:18.09-alpine-elixir-1.8.1
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: DOCKER_HOST 
      value: tcp://localhost:2375 
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "4048Mi"
        cpu: "2000m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "4048Mi"
        cpu: "2000m"
  - name: dind
    image: docker:18.09.2-dind
    securityContext: 
        privileged: true 
    ports:
    - containerPort: 2375
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "4048Mi"
        cpu: "4000m"
    volumeMounts: 
    - name: docker-graph-storage 
      mountPath: /var/lib/docker
  - name: mongo
    image: mvertes/alpine-mongo:4.0.1-0
    ports:
    - containerPort: 27017
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: redis
    image: redis:4-alpine3.9
    ports:
    - containerPort: 6379
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: kafkazookeeper
    image: johnnypark/kafka-zookeeper:2.1.0
    ports:
    - containerPort: 2181
    - containerPort: 9092
    env:
    - name: ADVERTISED_HOST
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
  nodeSelector:
    node: "$RD_CROP"
  volumes: 
    - name: docker-graph-storage 
      emptyDir: {}
"""
            }
          }
          steps {
            container(name: 'kafkazookeeper', shell: '/bin/sh') {
              sh 'cd /opt/kafka_2.12-2.1.0/bin && ./kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic merge_legal_entities'
            }
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for MergeLegalEntities consumer-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto make erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          // post {
          //   always {
          //     container(name: 'docker', shell: '/bin/sh') {
          //       sh 'echo " ---- step: Remove docker image from host ---- ";'
          //       sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
          //     }
          //   }
          // }
        }
        stage('Build deactivate-legal-entity-consumer') {
          environment {
            APPS='[{"app":"deactivate_legal_entity_consumer","chart":"il","namespace":"il","deployment":"deactivate-legal-entity-consumer","label":"deactivate-legal-entity-consumer"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label "deactivate-legal-entity-consumer-build-$NAME"
              defaultContainer 'jnlp'
              yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "ci"
    operator: "Equal"
    value: "$RD_CROP"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: liubenokvlad/docker:18.09-alpine-elixir-1.8.1
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: DOCKER_HOST 
      value: tcp://localhost:2375 
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "4048Mi"
        cpu: "2000m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "4048Mi"
        cpu: "2000m"
  - name: dind
    image: docker:18.09.2-dind
    securityContext: 
        privileged: true 
    ports:
    - containerPort: 2375
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "4048Mi"
        cpu: "4000m"
    volumeMounts: 
    - name: docker-graph-storage 
      mountPath: /var/lib/docker
  - name: mongo
    image: mvertes/alpine-mongo:4.0.1-0
    ports:
    - containerPort: 27017
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: redis
    image: redis:4-alpine3.9
    ports:
    - containerPort: 6379
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: kafkazookeeper
    image: johnnypark/kafka-zookeeper:2.1.0
    ports:
    - containerPort: 2181
    - containerPort: 9092
    env:
    - name: ADVERTISED_HOST
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
  nodeSelector:
    node: "$RD_CROP"
  volumes: 
    - name: docker-graph-storage 
      emptyDir: {}
"""
            }
          }
          steps {
            container(name: 'kafkazookeeper', shell: '/bin/sh') {
              sh 'cd /opt/kafka_2.12-2.1.0/bin && ./kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic deactivate_legal_entity_event'
            }
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for DeactivateLegalEntities consumer-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto make erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          // post {
          //   always {
          //     container(name: 'docker', shell: '/bin/sh') {
          //       sh 'echo " ---- step: Remove docker image from host ---- ";'
          //       sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
          //     }
          //   }
          // }
        }
        stage('Build ehealth-scheduler') {
          environment {
            APPS='[{"app":"ehealth_scheduler","chart":"il","namespace":"il","deployment":"ehealth-scheduler","label":"ehealth-scheduler"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label "ehealth-scheduler-build-$NAME"
              defaultContainer 'jnlp'
              yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "ci"
    operator: "Equal"
    value: "$RD_CROP"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: liubenokvlad/docker:18.09-alpine-elixir-1.8.1
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: DOCKER_HOST 
      value: tcp://localhost:2375
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "4048Mi"
        cpu: "2000m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
  - name: dind
    image: docker:18.09.2-dind
    securityContext: 
        privileged: true 
    ports:
    - containerPort: 2375
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "4048Mi"
        cpu: "2000m"
    volumeMounts: 
    - name: docker-graph-storage 
      mountPath: /var/lib/docker
  - name: mongo
    image: mvertes/alpine-mongo:4.0.1-0
    ports:
    - containerPort: 27017
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: redis
    image: redis:4-alpine3.9
    ports:
    - containerPort: 6379
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "300m"
  - name: kafkazookeeper
    image: johnnypark/kafka-zookeeper:2.1.0
    ports:
    - containerPort: 2181
    - containerPort: 9092
    env:
    - name: ADVERTISED_HOST
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
  nodeSelector:
    node: "$RD_CROP"
  volumes: 
    - name: docker-graph-storage 
      emptyDir: {}
"""
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for Scheduler-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          // post {
          //   always {
          //     container(name: 'docker', shell: '/bin/sh') {
          //       sh 'echo " ---- step: Remove docker image from host ---- ";'
          //       sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
          //     }
          //   }
          // }
        }
      }
    }
    stage ('Deploy') {
      when {
        allOf {
            environment name: 'CHANGE_ID', value: ''
            branch 'develop'
        }
      }
      environment {
        APPS = '[{"app":"ehealth","chart":"il","namespace":"il","deployment":"api","label":"api"},{"app":"casher","chart":"il","namespace":"il","deployment":"casher","label":"casher"},{"app":"graphql","chart":"il","namespace":"il","deployment":"graphql","label":"graphql"},{"app":"merge_legal_entities_consumer","chart":"il","namespace":"il","deployment":"merge-legal-entities-consumer","label":"merge-legal-entities-consumer"},{"app":"deactivate_legal_entity_consumer","chart":"il","namespace":"il","deployment":"deactivate-legal-entity-consumer","label":"deactivate-legal-entity-consumer"},{"app":"ehealth_scheduler","chart":"il","namespace":"il","deployment":"ehealth-scheduler","label":"ehealth-scheduler"}]'
      }
      agent {
        kubernetes {
          label 'ehealth-deploy'
          defaultContainer 'jnlp'
          yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: deploy
spec:
  tolerations:
  - key: "ci"
    operator: "Equal"
    value: "$RD_CROP"
    effect: "NoSchedule"
  containers:
  - name: kubectl
    image: lachlanevenson/k8s-kubectl:v1.13.2
    command:
    - cat
    tty: true
  nodeSelector:
    node: "$RD_CROP"
"""
        }
      }
      steps {
        container(name: 'kubectl', shell: '/bin/sh') {
          sh 'apk add curl bash jq'
          sh 'echo " ---- step: Deploy to cluster ---- ";'
          sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/autodeploy.sh -o autodeploy.sh; bash ./autodeploy.sh'
        }
      }
    }
  }
  post {
    success {
      slackSend (color: 'good', message: "SUCCESSFUL: Job - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) success in ${currentBuild.durationString}")
    }
    failure {
      slackSend (color: 'danger', message: "FAILED: Job - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) failed in ${currentBuild.durationString}")
    }
    aborted {
      slackSend (color: 'warning', message: "ABORTED: Job - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) canceled in ${currentBuild.durationString}")
    }
    always {
      node('delete-instance') {
        // checkout scm
        container(name: 'gcloud', shell: '/bin/sh') {
          withCredentials([file(credentialsId: 'e7e3e6df-8ef5-4738-a4d5-f56bb02a8bb2', variable: 'KEYFILE')]) {
            checkout scm
            sh 'apk update && apk add curl bash git'
            sh 'gcloud auth activate-service-account jenkins-pool@ehealth-162117.iam.gserviceaccount.com --key-file=${KEYFILE} --project=ehealth-162117'
            sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/delete_instance.sh -o delete_instance.sh; bash ./delete_instance.sh'
          }
          slackSend (color: '#4286F5', message: "Instance for ${env.BUILD_TAG} deleted")
        }
      }
    }
  }
}
