pipeline {
  agent {
    node { 
      label 'ehealth-build-big' 
      }
  }
  environment {
    PROJECT_NAME = 'ehealth'
    MIX_ENV = 'test'
    DOCKER_NAMESPACE = 'edenlabllc'
    POSTGRES_VERSION = '10'
    POSTGRES_USER = 'postgres'
    POSTGRES_PASSWORD = 'postgres'
    POSTGRES_DB = 'postgres'
  }
  stages {
    stage('Init') {
      options {
        timeout(activity: true, time: 3)
      }
      steps {
        sh 'cat /etc/hostname'
        sh 'sudo docker rm -f $(sudo docker ps -a -q) || true'
        sh 'sudo docker rmi $(sudo docker images -q) || true'
        sh 'sudo docker system prune -f'
        sh '''
          sudo docker run -d --name postgres -p 5432:5432 edenlabllc/alpine-postgre:pglogical-gis-1.1;
          sudo docker run -d --name mongo -p 27017:27017 edenlabllc/alpine-mongo:4.0.1-0;
          sudo docker run -d --name redis -p 6379:6379 redis:4-alpine3.9;
          sudo docker run -d --name kafkazookeeper -p 2181:2181 -p 9092:9092 edenlabllc/kafka-zookeeper:2.1.0;
          sudo docker ps;
        '''
        sh '''
          until psql -U postgres -h localhost -c "create database ehealth";
            do
              sleep 2
            done
          psql -U postgres -h localhost -c "create database prm_dev";
          psql -U postgres -h localhost -c "create database fraud_dev";
          psql -U postgres -h localhost -c "create database event_manager_dev";
        '''
        sh '''
          until sudo docker exec -i kafkazookeeper /opt/kafka_2.12-2.1.0/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic merge_legal_entities;
            do
              sleep 2
            done
          sudo docker exec -i kafkazookeeper /opt/kafka_2.12-2.1.0/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic deactivate_legal_entity_event;
          sudo docker exec -i kafkazookeeper /opt/kafka_2.12-2.1.0/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic edr_verification_events;
        '''
        sh '''
          mix local.hex --force;
          mix local.rebar --force;
          mix deps.get;
          mix deps.compile;
        '''
      }
    }
    stage('Test') {
      options {
        timeout(activity: true, time: 3)
      }
      steps {
        sh '''
          (curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/tests.sh -o tests.sh; chmod +x ./tests.sh; ./tests.sh) || exit 1;
          cd apps/graphql && mix white_bread.run
          if [ "$?" -eq 0 ]; then echo "mix white_bread.run successfully completed" else echo "mix white_bread.run finished with errors, exited with 1" is_failed=1; fi;
          '''
      }
    }
    stage('Build') {
      failFast true
      parallel {
        stage('Build ehealth-app') {
          options {
            timeout(activity: true, time: 3)
          }
          environment {
            APPS = '[{"app":"ehealth","chart":"il","namespace":"il","deployment":"api","label":"api"}]'
          }
          steps {
            sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/build-container.sh -o build-container.sh;
              chmod +x ./build-container.sh;
              ./build-container.sh;  
            '''
          }
        }
        stage('Build casher-app') {
          options {
            timeout(activity: true, time: 3)
          }
          environment {
            APPS = '[{"app":"casher","chart":"il","namespace":"il","deployment":"casher","label":"casher"}]'
          }
          steps {
            sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/build-container.sh -o build-container.sh;
              chmod +x ./build-container.sh;
              ./build-container.sh;  
            '''
          }
        }
        stage('Build graphql-app') {
          options {
            timeout(activity: true, time: 3)
          }
          environment {
            APPS = '[{"app":"graphql","chart":"il","namespace":"il","deployment":"graphql","label":"graphql"}]'
            // DB_MIGRATE = 'false'
          }
          steps {
            sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/build-container.sh -o build-container.sh;
              chmod +x ./build-container.sh;
              ./build-container.sh;
            '''
          }
        }
        stage('Build merge-legal-entities-consumer-app') {
          options {
            timeout(activity: true, time: 3)
          }
          environment {
            APPS = '[{"app":"merge_legal_entities_consumer","chart":"il","namespace":"il","deployment":"merge-legal-entities-consumer","label":"merge-legal-entities-consumer"}]'
          }
          steps {
            sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/build-container.sh -o build-container.sh;
              chmod +x ./build-container.sh;
              ./build-container.sh;
            '''
          }
        }
        stage('Build deactivate-legal-entity-consumer-app') {
          options {
            timeout(activity: true, time: 3)
          }
          environment {
            APPS = '[{"app":"deactivate_legal_entity_consumer","chart":"il","namespace":"il","deployment":"deactivate-legal-entity-consumer","label":"deactivate-legal-entity-consumer"}]'
          }
          steps {
            sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/build-container.sh -o build-container.sh;
              chmod +x ./build-container.sh;
              ./build-container.sh; 
            '''
          }
        }
        stage('Build edr-validations-consumer-app') {
          options {
            timeout(activity: true, time: 3)
          }
          environment {
            APPS = '[{"app":"edr_validations_consumer","chart":"il","namespace":"il","deployment":"edr-validations-consumer","label":"edr-validations-consumer"}]'
          }
          steps {
            sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/build-container.sh -o build-container.sh;
              chmod +x ./build-container.sh;
              ./build-container.sh;
            '''
          }
        }
        stage('Build ehealth-scheduler-app') {
          options {
            timeout(activity: true, time: 3)
          }
          environment {
            APPS = '[{"app":"ehealth_scheduler","chart":"il","namespace":"il","deployment":"ehealth-scheduler","label":"ehealth-scheduler"}]'
          }
          steps {
            sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/build-container.sh -o build-container.sh;
              chmod +x ./build-container.sh;
              ./build-container.sh;
            '''
          }
        }
      }
    }
    stage('Run eHealth-app and push') {
      options {
        timeout(activity: true, time: 3)
      }
      environment {
        APPS = '[{"app":"ehealth","chart":"il","namespace":"il","deployment":"api","label":"api"}]'
      }
      steps {
        sh '''
          curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/start-container.sh -o start-container.sh;
          chmod +x ./start-container.sh; 
          ./start-container.sh;
        '''
        withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh 'echo " ---- step: Push docker image ---- ";'
          sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/push-changes.sh -o push-changes.sh;
              chmod +x ./push-changes.sh;
              ./push-changes.sh
            '''
        }
      }
    }
    stage('Run casher-app and push') {
      options {
        timeout(activity: true, time: 3)
      }
      environment {
        APPS = '[{"app":"casher","chart":"il","namespace":"il","deployment":"casher","label":"casher"}]'
      }
      steps {
        sh '''
          curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/start-container.sh -o start-container.sh;
          chmod +x ./start-container.sh; 
          ./start-container.sh;
        '''
        withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh 'echo " ---- step: Push docker image ---- ";'
          sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/push-changes.sh -o push-changes.sh;
              chmod +x ./push-changes.sh;
              ./push-changes.sh
            '''
        }
      }
    }
    stage('Run graphQL-app and push') {
      options {
        timeout(activity: true, time: 3)
      }
      environment {
        APPS = '[{"app":"graphql","chart":"il","namespace":"il","deployment":"graphql","label":"graphql"}]'
      }
      steps {
        sh '''
          curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/start-container.sh -o start-container.sh;
          chmod +x ./start-container.sh; 
          ./start-container.sh;
        '''
        withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh 'echo " ---- step: Push docker image ---- ";'
          sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/push-changes.sh -o push-changes.sh;
              chmod +x ./push-changes.sh;
              ./push-changes.sh
            '''
        }
      }
    }
    stage('Run merge-legal-entities-consumer-app and push') {
      options {
        timeout(activity: true, time: 3)
      }
      environment {
        APPS = '[{"app":"merge_legal_entities_consumer","chart":"il","namespace":"il","deployment":"merge-legal-entities-consumer","label":"merge-legal-entities-consumer"}]'
      }
      steps {
        sh '''
          curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/start-container.sh -o start-container.sh;
          chmod +x ./start-container.sh; 
          ./start-container.sh;
        '''
        withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh 'echo " ---- step: Push docker image ---- ";'
          sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/push-changes.sh -o push-changes.sh;
              chmod +x ./push-changes.sh;
              ./push-changes.sh
            '''
        }
      }
    }
    stage('Run deactivate-legal-entity-consumer-app and push') {
      options {
        timeout(activity: true, time: 3)
      }
      environment {
        APPS = '[{"app":"deactivate_legal_entity_consumer","chart":"il","namespace":"il","deployment":"deactivate-legal-entity-consumer","label":"deactivate-legal-entity-consumer"}]'
      }
      steps {
        sh '''
          curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/start-container.sh -o start-container.sh;
          chmod +x ./start-container.sh; 
          ./start-container.sh;
        '''
        withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh 'echo " ---- step: Push docker image ---- ";'
          sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/push-changes.sh -o push-changes.sh;
              chmod +x ./push-changes.sh;
              ./push-changes.sh
            '''
        }
      }
    }
    stage('Run edr-validations-consumer-app and push') {
      options {
        timeout(activity: true, time: 3)
      }
      environment {
        APPS = '[{"app":"edr_validations_consumer","chart":"il","namespace":"il","deployment":"edr-validations-consumer","label":"edr-validations-consumer"}]'
      }
      steps {
        sh '''
          curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/start-container.sh -o start-container.sh;
          chmod +x ./start-container.sh; 
          ./start-container.sh;
        '''
        withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh 'echo " ---- step: Push docker image ---- ";'
          sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/push-changes.sh -o push-changes.sh;
              chmod +x ./push-changes.sh;
              ./push-changes.sh
            '''
        }
      }
    }
    stage('Run ehealth-scheduler-app and push') {
      options {
        timeout(activity: true, time: 3)
      }
      environment {
        APPS = '[{"app":"ehealth_scheduler","chart":"il","namespace":"il","deployment":"ehealth-scheduler","label":"ehealth-scheduler"}]'
      }
      steps {
        sh '''
          curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/start-container.sh -o start-container.sh;
          chmod +x ./start-container.sh; 
          ./start-container.sh;
        '''
        withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh 'echo " ---- step: Push docker image ---- ";'
          sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/push-changes.sh -o push-changes.sh;
              chmod +x ./push-changes.sh;
              ./push-changes.sh
            '''
        }
      }
    }
    stage('Deploy') {
      options {
        timeout(activity: true, time: 3)
      }
      environment {
        APPS = '[{"app":"ehealth","chart":"il","namespace":"il","deployment":"api","label":"api"},{"app":"casher","chart":"il","namespace":"il","deployment":"casher","label":"casher"},{"app":"graphql","chart":"il","namespace":"il","deployment":"graphql","label":"graphql"},{"app":"merge_legal_entities_consumer","chart":"il","namespace":"il","deployment":"merge-legal-entities-consumer","label":"merge-legal-entities-consumer"},{"app":"deactivate_legal_entity_consumer","chart":"il","namespace":"il","deployment":"deactivate-legal-entity-consumer","label":"deactivate-legal-entity-consumer"},{"app":"edr_validations_consumer","chart":"il","namespace":"il","deployment":"edr-validations-consumer","label":"edr-validations-consumer"},{"app":"ehealth_scheduler","chart":"il","namespace":"il","deployment":"ehealth-scheduler","label":"ehealth-scheduler"}]'
      }
      steps {
        withCredentials([string(credentialsId: '86a8df0b-edef-418f-844a-cd1fa2cf813d', variable: 'GITHUB_TOKEN')]) {
          withCredentials([file(credentialsId: '091bd05c-0219-4164-8a17-777f4caf7481', variable: 'GCLOUD_KEY')]) {
            sh '''
              curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins_gce/autodeploy.sh -o autodeploy.sh;
              chmod +x ./autodeploy.sh;
              ./autodeploy.sh
            '''
          }
        }
      }
    }
  }
}

