## The repository contains the following:

- [init.sql](#init.sql) - contains the init script to bootstrap and seed the mysql db
- [Common](#common) - java/maven project with common entity classes
- [Producer](#producer) - java/maven project (spring-boot app) that binds to http port 9000 reads from the db and publishes data to kafka
- [Consumer](#Consumer) - java/maven project (spring-boot app) that consumes the kafka topic and updates the db
- [Terraform-Module](#Terraform-Module)    - Create EKS cluster with terraform module that includes "Cluster-autoscaler && HPA && Metric-server"
- [Kafka-Chart](#Kafka-Chart)         - Deploy Kafka helm chart with all the best practices
- [MySQL-Chart](#MySQL-Chart)         - Deploy MySQL helm chart with all the best practices
- [kafka-client](#kafka-client)        - Deploy a kafka client to run commands on the cluster
- [Project-Images](#Project-Images)        - Project Images (cluster status, producer logs, consumer logs, kafka topic logs)



## Terraform

Building EKS Cluster via Terraform:

- `terraform init`
- `terraform plan`
- `terraform apply`

## MySQL:

##### Create Docker image with the init.sql script:

- `docker tag 018876cb57ef 048610927396.dkr.ecr.eu-west-1.amazonaws.com/devops`
- `docker push 048610927396.dkr.ecr.eu-west-1.amazonaws.com/devops`

##### MySQL Helm Chart

- `MySQL service name = db-mysql`
- `MySQL port number  = 3306`

##### K8S commands:

- `helm install --name db -f mysql/values.yaml --set mysqlRootPassword=****,mysqlUser=****,mysqlPassword=****,mysqlDatabase=Payoneer stable/mysql`

### Kafka

##### Building Kafka and deploy to the cluster:

- `kafka service name = my-kafka`
- `kafka port number  = 9092`
- `kafka topic name  = charges`

##### K8S commands:

- `helm install --name my-kafka -f kafka/values.yaml incubator/kafka`

### Using Kafka Client(pod) to run kafka commands from the Kubernetes cluster:

You can connect to Kafka by running a simple pod in the K8s cluster like this with a configuration like this:

- `kubectl apply -f kafka/kafka.yaml`

Once you have the testclient pod above running, you can list all kafka
topics with:

- `kubectl -n default exec kafka-client -- ./bin/kafka-topics.sh --zookeeper my-kafka-zookeeper:2181 --list`

To create a new topic:

- `kubectl -n default exec kafka-client -- ./bin/kafka-topics.sh --zookeeper my-kafka-zookeeper:2181 --topic charges --create --partitions 1 --replication-factor 1`

To listen for messages on a topic:

- `kubectl -n default exec -ti kafka-client -- ./bin/kafka-console-consumer.sh --bootstrap-server my-kafka:9092 --topic charges --from-beginning`

To start an interactive message producer session:

- `kubectl -n default exec -ti kafka -- ./bin/kafka-console-producer.sh --broker-list my-kafka-headless:9092 --topic charges`

To create a message in the above session, simply type the message and press "enter"
To end the producer session try: Ctrl+C

### Build jar files with maven:

1. `mvn install ./common`
2. `mvn install -Dmaven.test.skip=true -f ./producer`
3. `mvn install -Dmaven.test.skip=true -f ./consumer`

### Containerazation the apps:

1. `docker build -t 048610927396.dkr.ecr.eu-west-1.amazonaws.com/producer ./producer`
2. `docker build -t 048610927396.dkr.ecr.eu-west-1.amazonaws.com/consumer ./consumer`
3. `docker push 048610927396.dkr.ecr.eu-west-1.amazonaws.com/producer`
4. `docker push 048610927396.dkr.ecr.eu-west-1.amazonaws.com/consumer`

## Deploy Producer
- `kubectl apply -f producer/producer.yaml`


## Deploy Consumer
- `kubectl apply -f consumer/consumer.yaml`


### TEST:

1. `kubectl exec -it kafka-client bash`
2. `curl -XPOST "http://producer:9000/producer/?count=100"`
3. `kubectl logs consumer-fd89d97c6-4c45c`
4. `kubectl logs producer-86d4df49bd-4xwmt`

#### HPA Load testing:

# Generate load to trigger scaling

1. `kubectl run -i --tty load-generator --image=busybox /bin/sh` (or we can use our Kafka-client)
2. `while true; do curl -XPOST "http://producer:9000/producer/?count=100"; done`
3. `kubectl get hpa -w`

#### Cluster auto scaler Load testing:

1. `kubectl run php-apache --image=k8s.gcr.io/hpa-example --requests=cpu=200m --expose --port=80 --replicas=50`
2. `kubectl get nodes -w`