Spring Boot Microservices Demo Project
================================
This project showcases a microservices architecture built using Java 21 and Spring Boot. It includes multiple microservices that communicate with each other through RESTful APIs and asynchronous messaging using Kafka. The architecture also incorporates an API Gateway for routing and a Eureka Server for service discovery.

Note : This project is intended for educational purposes. Microservices include basic implementations to demonstrate inter-service communication, resilience patterns, and deployment strategies.

High-level Architecture
================================
The microservices architecture consists of the following components:

1. **Eureka Server**: Acts as a service registry for service discovery(Applicable to only local docker deployment).
2. **API Gateway**: Routes requests to appropriate microservices and provides a single entry point.
3. **User Service**: Manages user-related operations and data.
4. **Order Service**: Manages order-related operations and communicates with other services.
5. **Payment Service**: Handles payment processing.
6. **Notification Service**: Sends notifications to users via email or SMS.
7. **Inventory Service**: Manages product inventory and stock levels.

Each service is designed to be independently deployable and scalable. The services communicate with each other using RESTful APIs and Asynchronous Messaging (Kafka), and the API Gateway handles routing and load balancing. The Eureka Server enables service discovery, allowing services to find and communicate with each other dynamically.

Communication Flow
--------------------------------
1. A client sends a request to the API Gateway.
2. The API Gateway routes the request to the appropriate microservice (e.g., User Service).
3. The microservice processes the request, which may involve communicating with other microservices using REST APIs or Feign Client.
4. The microservices may use Kafka for asynchronous communication, such as sending notifications.
5. The response is sent back through the API Gateway to the client.


### Technologies Used
- Java 21
- Spring Boot
- Spring Cloud Netflix Eureka (Service Discovery)
- Spring Cloud Gateway (API Gateway)
- Resilience4j (Circuit Breaker)
- Maven
- Docker
- Kafka
- Buildpacks for Docker image creation
- GitHub Actions (CI/CD)
- Azure (Container Apps, Container Registry, Federated Identity)

  Project Setup Instructions
  ================================

**Note**: the project can be run locally using Docker or deployed to Azure using a CI/CD pipeline configured with GitHub Actions.

1. **Clone the Repository**: Clone the project repository to your local machine.
```bash
git clone https://github.com/gorantlapc/Springboot-microservices.git
```
Run locally using Docker
--------------------------------
1. ``` bash
   git checkout local-docker-deployment
    ```
2. **Install Docker**: Ensure Docker Desktop is installed and running on your machine.
3. **Build the Project**: Navigate to the project directory.
   1. **Build All services**: Run `./mvnw clean spring-boot:build-image` to build the project and create Docker images for each microservice.
   2. **Build Single Service**: Run `./mvnw clean spring-boot:build-image -pl <module-name>` to build a specific microservice module. Replace `<module-name>` with the desired module name (e.g., `order-service`).
4. **Run Services**: Run the command `docker-compose up -d` to start all the microservices along with Kafka.
5. **Access the Services**: Use Postman or any API testing tool to interact with the microservices through the API Gateway.

Example: `http://localhost:8084/order/process` and pass order details through request body as below to access the User Service.
```json
{
  "orderId": "12536",
  "userEmail": "pcatgothenburg@gmail.com",
  "productCode": "2000",
  "quantity": 4,
  "price": 2000
}
```
Run using CI/CD Pipeline
--------------------------------
1. **Azure Setup**: Ensure you have an Azure account with Azure Container Registry and Azure Container Apps set up and Azure Federated Identity configured.
   Run the script `./scripts/setup-azure-resources.sh` to create the required Azure resources.
2. **Configure Secrets**: Add the necessary secrets to your GitHub repository for Azure authentication and other configurations.
3. **Set ENV Variables**: set environment variables in github repository settings as below
    - AZURE_CLIENT_ID: your-azure-client-id
    - AZURE_CONTAINER_REGISTRY: your-azure-container-registry-name
    - AZURE_CONTAINER_REGISTRY_NAME : your-azure-container-registry-login-server-name
    - AZURE_TENANT_ID: your-azure-tenant-id
    - AZURE_RESOURCE_GROUP: your-azure-resource-group-name
    - AZURE_SUBSCRIPTION_ID: your-azure-subscription-id
4. ``` bash
      git checkout deploy_to_azure
    ```
5. **Push to GitHub**: Push your code changes to the GitHub repository.
6. **GitHub Actions**: The CI/CD pipeline defined in `.github/workflows/main.yml` will automatically build image and push images to Azure Container Registry.
7. **Deployment**: The pipeline will deploy the microservices to Azure Container Apps.

**To Do**: When it comes to Cloud deployment, we need to fix Kafka setup in Azure Or use equivalent azure alternative.

Problems and solutions
====================
Problem 1: Circuit breaker not invoked when downstream service is down or throws error
Root Cause: Missed to add spring aop dependency which requires by Resilience4j
Solution: Add the following dependency to pom.xml
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

Problem 2: Can't convert value of class com.gorantla.orderservice.data.Message to class org.apache.kafka.common.serialization.StringSerializer specified in value.serializer
Root Cause: Incorrect Kafka producer configuration. it should be spring.kafka.producer.value-serializer. it was given as kafka.producer.value-serializer
Solution: Update the application.yml correctly as below
```yaml
spring:
  kafka:
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.JsonSerializer
```

Problem 3: org.springframework.beans.TypeMismatchException: Failed to convert value of type 'java.lang.String' to required type 'java.lang.Class'; Could not find class [org.apache.kafka.common.serialization.JsonSerializer]
Roor Cause: Standard Apache Kafka only provides serializers for simple types (String, Integer, Bytes). The JsonSerializer is a Spring-specific utility.
Solution: Update the application.yml to use Spring Kafka's JsonSerializer as below
```yaml
spring:
  kafka:
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
```
 
Problem 4: Get error while run github action.
Run ./mvnw -B clean package -DskipTests --file pom.xml /home/runner/work/_temp/bb652d7d-9c6b-43e7-92c3-3023fc363d1c.sh: line 1: ./mvnw: Permission denied.
Root Cause: The Maven Wrapper script (mvnw) does not have execute permissions for Github runner(Linux).
Solution: Run the following command to give execute permission to mvnw and commit the changes.
```bash
chmod +x mvnw
git add mvnw
git commit -m "Give execute permission to mvnw"
git push
``` 
This solution does not impact local development environments like Windows or MacOS, as they handle file permissions differently.
You must do it from a Linux or WSL terminal.

Or add the following step in github action before executing mvnw command.
```yaml
- name: Give execute permission to mvnw
  run: chmod +x mvnw