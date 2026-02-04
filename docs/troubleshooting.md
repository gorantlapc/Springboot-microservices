# Troubleshooting

This document contains the "Problems and solutions" section extracted from the project's README.

**Problem 1**: Circuit breaker not invoked when downstream service is down or throws error

**Root Cause**: Missed to add spring aop dependency which requires by Resilience4j

**Solution**: Add the following dependency to pom.xml
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

**Problem 2**: Can't convert value of class com.gorantla.orderservice.data.Message to class org.apache.kafka.common.serialization.StringSerializer specified in value.serializer

**Root Cause**: Incorrect Kafka producer configuration. it should be spring.kafka.producer.value-serializer. it was given as kafka.producer.value-serializer

**Solution**: Update the application.yml correctly as below
```yaml
spring:
  kafka:
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.JsonSerializer
```

**Problem 3**: org.springframework.beans.TypeMismatchException: Failed to convert value of type 'java.lang.String' to required type 'java.lang.Class'; Could not find class [org.apache.kafka.common.serialization.JsonSerializer]

**Roor Cause**: Standard Apache Kafka only provides serializers for simple types (String, Integer, Bytes). The JsonSerializer is a Spring-specific utility.

**Solution**: Update the application.yml to use Spring Kafka's JsonSerializer as below
```yaml
spring:
  kafka:
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
```
 
**Problem 4**: Get error while run github action.
Run ./mvnw -B clean package -DskipTests --file pom.xml /home/runner/work/_temp/bb652d7d-9c6b-43e7-92c3-3023fc363d1c.sh: line 1: ./mvnw: Permission denied.

**Root Cause**: The Maven Wrapper script (mvnw) does not have execute permissions for Github runner(Linux).

**Solution**: Run the following command to give execute permission to mvnw and commit the changes.
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
```

**Problem 5**: io.netty.resolver.dns.DnsResolveContext$SearchDomainUnknownHostException: Failed to resolve 'order-service-app.internal' [A(1)] and search domain query for configured domains failed as well: [k8se-apps.svc.cluster.local, svc.cluster.local, cluster.local]

**Root Cause**: The error errors when the api-gateway-app is trying to reach the order-service-app. This error occurs because Netty (the underlying networking library for Spring WebFlux/Project Reactor) uses its own Java-based DNS resolver which often conflicts with how Azure Container Apps (ACA) handles internal service discovery.

**Solution**: To resolve this issue, you need to configure Netty to use the system DNS resolver instead of its default Java-based resolver. 

Set the environment variables as below
JAVA_TOOL_OPTIONS="-Dnetty.dns.resolver.type=native" and URL should be like http://order-service-app without port number.

This change forces Netty to use the system's DNS resolver, which is compatible with ACA's internal DNS resolution mechanism. After making this change, restart the Azure Container App (api-gateway-app), and the DNS resolution issues should be resolved. 

**Problem 6**: Dapr sidecar is not starting in Azure Container Apps

**Root Cause**: Missing Dapr configuration in Azure Container App.

**Solution**: Enable Dapr in Azure Container App using Azure CLI as below
Pass the following attributes to the command az containerapp create or az containerapp update
```bash
--enable-dapr true
--dapr-app-id notification-service
--dapr-app-port 8087
--dapr-app-protocol http
```
Or run the following command to enable Dapr in existing container app
```bash
$ az containerapp dapr enable --name notification-service-app --resource-group springboot-rg --dapr-app-id notification-service --dapr-app-port 8087 --dapr-app-protocol http
``` 

**Problem 7**: Image name and tag is not set to container app during deployment from ACR when updating container app using github action.

**Root Cause:** Using latest tag in container app deployment step in github action.

**Solution:** Use specific image tag instead of latest in container app deployment step in github action as below
use the following format
```yaml
image: ${{AZURE_CONTAINER_REGISTRY_NAME}}/notification-service:${{ github.sha }}
```
but still image is built with latest tag because of buildpack default behavior based configuration done in pom.xml.
To fix that we need to explicitly set the tag during image build step as below
```yaml
./mvnw clean spring-boot:build-image -Dimage.name=${{ AZURE_CONTAINER_REGISTRY_NAME }}/notification-service:${{ github.sha }} -pl notification-service
```
**Problem 8**: software.amazon.awssdk.services.sns.model.SnsException: The security token included in the request is invalid. (Service: Sns, Status Code: 403, Request ID: dd04c08f-3a50-5576-9931-a162fe7dddb1)

**Root Cause**: When you configure access-key / secret-key explicitly (directly or via env vars)
credentials:
access-key: ${AWS_ACCESS_KEY}
secret-key: ${AWS_SECRET_KEY}
The SDK uses these credentials and ignores the role assigned to the container.

**Solution**: Remove the explicit access-key / secret-key configuration and rely on the IAM role assigned to the container for authentication.

**Problem 9:** Caused by: java.util.concurrent.CompletionException: io.awspring.cloud.sqs.QueueAttributesResolvingException: Error resolving attributes for queue dev-events-queue with strategy CREATE and queueAttributesNames []
It means your app is trying to create the SQS queue, not just use it — and IAM doesn’t allow that.

**Root Cause:** The application is trying to create the SQS queue instead of just using it, which is not permitted by the assigned IAM role.

**Solution**: Ensure that the SQS queue already exists and that the application is configured to use the existing queue rather than attempting to create it. 
Check your application configuration for any settings related to queue creation and adjust them accordingly.
application.yml
```yaml
spring:
  cloud:
    aws:
      sqs:
        auto-create: false
```
**Problem 10:** service dev-api-gateway-service was unable to place a task. Reason: ResourceInitializationError: unable to pull secrets or registry auth: The task cannot pull registry auth from Amazon ECR: There is a connection issue between the task and Amazon ECR. Check your task network configuration. operation error ECR: GetAuthorizationToken, exceeded maximum number of attempts, 3, https response error StatusCode: 0, RequestID: , request send failed, Post "https://api.ecr.eu-north-1.amazonaws.com/": dial tcp 13.53.180.123:443: i/o timeout.

**Root Cause**: The ECS task execution role does not have the necessary permissions to pull images from Amazon ECR.

**Solution**: Ensure that the ECS task execution role has the AmazonECSTaskExecutionRolePolicy attached. This policy grants the necessary permissions to pull images from ECR.

**Problem 11:** Tasks running private subnets in AWS ECS Fargate cannot access other AWS services like SNS or SQS.

**Root Cause**: The ECS tasks are running in private subnets without endpoints for the required AWS services, leading to connectivity issues.

**Solution**: Create VPC endpoints for the required AWS services (e.g., SNS, SQS) in your VPC. This allows ECS tasks in private subnets to communicate with these services without needing internet access.

**Problem 12:** AWS ECS Fargate tasks are stopping wit error 1

**Root Cause**: The ECS tasks are running out of memory due to insufficient memory allocation. Paket buildpacks automatically calculate JVM memory settings based on the total memory allocated to the container. If the container is allocated too little memory, the JVM may not have enough memory to operate, leading to task termination.
-XX:MaxDirectMemorySize=10M
10MB is the JVM default value set by paketo memory calculator. 10MB is very small for any modern Java application, especially one using Spring or AWS.
spring.cloud.aws and Spring Boot stack use Netty for networking. Netty relies on Direct Memory to buffer data for network sockets.
When that 10MB limit is reached, Netty will block and wait for a Garbage Collection to free up a buffer. If the GC can't free enough space immediately, your network threads stop responding.
And leaving headroom to zero will cause OOMKilled by the platform.

**Solution:** First I set JAVA_TOOL_OPTIONS, but it did not help because the options were overridden by paketo memory calculator.
Next I used the option -XX:MaxRAMPercentage, but it also did not help because paketo memory calculator injects flags like -Xmx. Then MaxRAMPercentage is ignored due JVM rule that If -Xmx is present, MaxRAMPercentage is ignored

Finally set MEMORY 1GB, JAVA_TOOL_OPTIONS with -XX:+UseG1GC -Xmx512m -Xms256m -XX:MaxMetaspaceSize=128M -XX:MaxDirectMemorySize=64M -XX:ReservedCodeCacheSize=64M for some services Or 
memory 2GB, JAVA_TOOL_OPTIONS with -XX:+UseG1GC -Xmx768m -Xms256m -XX:MaxMetaspaceSize=128M -XX:MaxDirectMemorySize=128M -XX:ReservedCodeCacheSize=128M for other services. Those are defined in terraform configuration for container apps.
and set the environment variable BPL_JVM_HEAD_ROOM to 20. This setting tells the Paketo memory calculator to reserve 25% of the container memory for overhead, leaving 80% for the JVM heap and other memory needs.

