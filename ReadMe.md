# SpringBoot Microservices Azure/AWS Cloud Deployment Demo Project

This project showcases a microservices architecture built using Java 21, Spring Boot and deploy to Azure Container Apps or AWS ECS. 
It includes multiple microservices that communicate with each other through RESTful APIs, Feign Client and asynchronous messaging using Kafka / Azure ServiceBus / Amazon SNS/SQS.

> Note: This project is intended for educational purposes. Microservices include basic implementations to demonstrate inter-service communication, resilience patterns, and deployment strategies.

## High-level architecture

The microservices architecture consists of the following components:

1. **Eureka Server**: Acts as a service registry for service discovery (applicable to only local Docker deployment).
2. **API Gateway**: Routes requests to appropriate microservices and provides a single entry point.
3. **User Service**: Manages user-related operations and data.
4. **Order Service**: Manages order-related operations and communicates with other services.
5. **Payment Service**: Handles payment processing.
6. **Notification Service**: Sends notifications to users via email or SMS.
7. **Inventory Service**: Manages product inventory and stock levels.

Each service is designed to be independently deployable and scalable. The services communicate with each other using RESTful APIs and asynchronous messaging (Kafka/Azure ServiceBus/AWS SNS/SQS). The API Gateway handles routing and load balancing. The Eureka Server enables service discovery, allowing services to find and communicate with each other dynamically.

## Request flows    

### Local (docker-compose + Kafka)

1. A client sends a request to the API Gateway.
2. The API Gateway routes the request to the appropriate microservice (e.g., User Service).
3. The microservice processes the request, which may involve communicating with other microservices using REST APIs or Feign Client.
4. The microservices may use Kafka for asynchronous communication, such as sending notifications.
5. The response is sent back through the API Gateway to the client.

### Azure Container Apps with Dapr integration (Azure Service Bus via Dapr)

1. A client sends a request to the API Gateway.
2. The API Gateway routes the request to the appropriate microservice (e.g., User Service).
3. The microservice processes the request, which may involve communicating with other microservices using Dapr HTTP APIs.
4. The microservices use the Dapr sidecar to publish messages to Azure Service Bus for asynchronous communication, such as sending notifications.
5. The response is sent back through the API Gateway to the client.

###  AWS deployment to ECS (SNS, SQS, SES)

1. A client sends a request to the API Gateway via Public ALB(Application Load Balancer).
2. The API Gateway routes the request to the appropriate microservice through Private ALB.
3. The microservice processes the request, which may involve communicating with other microservices using REST APIs/Feign Client.
4. The response is sent back through the API Gateway to the client.
5. The microservices use AWS SNS and SQS for asynchronous communication, such as sending notifications.
   For example; Order Service publishes order events to an SNS topic. SNS then delivers these messages to subscribed SQS queues, SqsListener in Notification Service polls the SQS queue to process and send notifications.
   For email notifications, AWS SES is used to send emails to users.

## Git branches

- `local-docker-deployment`: This branch is configured for local deployment using Docker and Docker Compose with Kafka for asynchronous messaging.
- `dapr-integration`: This branch is configured for deployment to Azure using a CI/CD pipeline with GitHub Actions and utilizes Dapr for asynchronous messaging via Azure Service Bus.
- `update-docs`: This branch is used for updating documentation and does not contain any code changes.
- `dev`: This branch is used for active development and may contain experimental features or changes.
- `main`: This is the default branch and may contain stable code or be used for other purposes.
- `deploy_to_aws`: This branch is configured for deployment to AWS using a CI/CD pipeline with GitHub Actions.

## Technologies used

- Java 21
- Spring Boot
- Spring Cloud Netflix Eureka (Service Discovery)
- Spring Cloud Gateway (API Gateway)
- Resilience4j (Circuit Breaker)
- Maven
- Docker
- Docker Compose
- Kafka
- Buildpacks for Docker image creation
- GitHub Actions (CI/CD)
- Azure (CLI, Container Apps, Container Registry, Federated Identity, Service Bus via Dapr)
- AWS (ECS, ECR, IAM, SNS, SQS, SES, VPC, ALB) (in `deploy_to_aws` branch)
- Terraform (in `deploy_to_aws` branch)

## Project setup instructions

> Note: The project can be run locally using Docker or deployed to Azure using a CI/CD pipeline configured with GitHub Actions.

### Clone the repository

```bash
git clone https://github.com/gorantlapc/Springboot-microservices.git
```

### Run locally using Docker

1. Switch to the branch for local deployment:

    ```bash
    git checkout local-docker-deployment
    ```

2. Install Docker Desktop and ensure it is running.

3. Build the project (from repository root):

- Build all services and create Docker images:

    ```bash
    ./mvnw clean spring-boot:build-image
    ```

- Build a single service (replace <module-name> with e.g. `order-service`):

    ```bash
    ./mvnw clean spring-boot:build-image -pl <module-name>
    ```

4. Start services using Docker Compose:

    ```bash
    docker compose up -d
    ```

5. Access the services through the API Gateway (example):

    POST http://localhost:8084/order/process

    Request body example:

    ```json
    {
      "orderId": "12536",
      "userEmail": "pcatgothenburg@gmail.com",
      "productCode": "2000",
      "quantity": 4,
      "price": 2000
    }
    ```

### Run using CI/CD pipeline and deploy to Azure

1. Azure setup: Ensure you have an Azure account with an Azure Container Registry and Azure Container Apps set up. Configure Azure Federated Identity as required.

2. Enable Dapr in Azure Container Apps (if using Dapr) and configure Dapr components for Service Bus.

3. Run the setup script to create required Azure resources (if provided):

    ```bash
    ./scripts/setup-azure-resources.sh
    ```

4. Configure repository secrets and environment variables in GitHub (examples):

  - AZURE_CLIENT_ID
  - AZURE_CONTAINER_REGISTRY
  - AZURE_CONTAINER_REGISTRY_NAME
  - AZURE_TENANT_ID
  - AZURE_RESOURCE_GROUP
  - AZURE_SUBSCRIPTION_ID

5. Switch to the Dapr integration branch and push changes:

    ```bash
    git checkout dapr-integration
    git push
    ```

6. The GitHub Actions workflow (`.github/workflows/main.yml`) will build images and push them to Azure Container Registry, and then deploy to Azure Container Apps.

> Note: Implementation of asynchronous messaging in `dapr-integration` branch uses Azure Service Bus via Dapr.

### Deploy microservices to AWS

1. Switch to the AWS deployment branch:

```bash
   git checkout deploy_to_aws
```

#### Run locally using Docker and localstack for AWS services

1. Build the project (from repository root):
   - Build all services and create Docker images:

```bash
   ./mvnw clean spring-boot:build-image -DskipTests
```

2. Start localstack and services using Docker Compose:

    ```bash
      docker-compose up -d
    ```
3. Run the awslocal.sh script to create required AWS resources in localstack. Script needs to be run on localstack container.

   - Copy the script into the container. localstack container name is localstack-main defined in docker-compose file.

     ```bash
      docker cp ./infra/scripts/awslocal.sh localstack-main:/tmp/awslocal.sh
      docker exec -it localstack-main bash -c "chmod +x /tmp/awslocal.sh && /tmp/awslocal.sh"
     ```
4. Access the services through the API Gateway (example):

   POST http://localhost:8084/api/order/process

   Request body example:

    ```json
    {
    "orderId": "12536",
    "userEmail": "pcatgothenburg@gmail.com",
    "productCode": "2000",
    "quantity": 4,
    "price": 2000
    }
    ```

#### To AWS using CI/CD pipeline

2. AWS setup: Ensure you have an AWS account with necessary IAM roles and permissions.

   Refer to the Terraform scripts in the `deploy_to_aws` branch for infrastructure setup. Scripts are located in the infra/envs/dev folder.
   Run the Terraform scripts to create the required AWS resources as below.

   Install Terraform and configure AWS CLI with appropriate credentials.

    ```bash
    cd infra/envs/dev
    terraform init
    terraform plan
    terraform apply
    ```
> Note: There is github action workflow file in .github/workflows/aws_infra_setup.yml to setup aws infrastructure using terraform. 
   But it is recommended to run terraform commands locally for now because of the state management. We still need to set up remote state management using S3 and DynamoDB for locking.
   
3. Configure repository secrets and environment variables in GitHub:
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY
   - AWS_REGION
   - AWS_ECS_CLUSTER

4. Push changes to the `deploy_to_aws` branch:
5. The GitHub Actions workflow (`.github/workflows/aws_ci_cd.yml`) will build images, push them to AWS ECR, and deploy to AWS ECS.
6. We have configured Public ALB to route traffic to api-gateway service and private ALB to route traffic between internal services.
   Access the services through the Public ALB DNS (example):
    POST http://<public-alb-dns>//api/order/process (POST http://dev-alb-1833499178.eu-north-1.elb.amazonaws.com/api/order/process)
    
    Request body example:
    
    ```json
    {
    "orderId": "1276",
    "userEmail": "pcatgothenburg@gmail.com",
    "productCode": "2345",
    "quantity": 3,
    "price": 5400
    }
    ```
   Response example:
   ```json
   {
      "orderStatus": "ORDER_CREATED",
      "orderRequest": {
      "orderId": "1276",
      "userEmail": "pcatgothenburg@gmail.com",
      "productCode": "2345",
      "quantity": 3,
      "price": 5400
      }
     }
      ```
And Order confirmation email is received to userEmail (Sender and Receiver mail has to be verified in AWS SES sandbox environment).      

## Troubleshooting

For problems and solutions, see the dedicated troubleshooting document: [docs/troubleshooting.md](docs/troubleshooting.md)

---
    
