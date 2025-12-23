Spring Boot Microservices Demo Project
================================
This project showcases a microservices architecture built using Java 21 and Spring Boot. It includes multiple microservices that communicate with each other through RESTful APIs and asynchronous messaging using Kafka. The architecture also incorporates an API Gateway for routing and a Eureka Server for service discovery.

High-level Architecture
================================
The microservices architecture consists of the following components:

1. **Eureka Server**: Acts as a service registry for service discovery.
2. **API Gateway**: Routes requests to appropriate microservices and provides a single entry point.
3. **User Service**: Manages user-related operations and data.
4. **Order Service**: Manages order-related operations and communicates with other services.
5. **Payment Service**: Handles payment processing and integrates with external payment gateways.
6. **Notification Service**: Sends notifications to users via email or SMS.

Each service is designed to be independently deployable and scalable. The services communicate with each other using RESTful APIs and Asynchronous Messaging (Kafka), and the API Gateway handles routing and load balancing. The Eureka Server enables service discovery, allowing services to find and communicate with each other dynamically.

Communication Flow
--------------------------------
1. A client sends a request to the API Gateway.
2. The API Gateway routes the request to the appropriate microservice (e.g., User Service).
3. The microservice processes the request, which may involve communicating with other microservices using REST APIs (e.g., Order Service).
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

  Project Setup Instructions
  ================================
1. **Clone the Repository**: Clone the project repository to your local machine.
2. **Build the Project**: Navigate to the project directory and run `./mvnw spring-boot:build-image clean install` to build the project and download dependencies.
3. **Run Services**: Run the command `docker-compose up -d` to start all the microservices along with Kafka and Eureka Server.
4. **Access the Services**: Use Postman or any API testing tool to interact with the microservices through the API Gateway.
Example: `http://localhost:8084/order/process` and pass order order details through request body as below to access the User Service.
```json
{
  "orderId": "12536",
  "userEmail": "pcatgothenburg@gmail.com",
  "productCode": "2000",
  "quantity": 4,
  "price": 2000
}
```

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
 
