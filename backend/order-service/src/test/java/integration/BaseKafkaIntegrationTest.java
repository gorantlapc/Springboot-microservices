package integration;

import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.KafkaContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

/**
 * Base class for Kafka integration tests.
 * This class sets up a Kafka container using Testcontainers and configures Spring Boot properties
 * to connect to the Kafka instance for testing purposes.
 *
 * By extending this class, any test will have access to a running Kafka broker and can produce/consume messages
 * as part of the integration tests.
 */
@Testcontainers
public abstract class BaseKafkaIntegrationTest {

    @Container
    static KafkaContainer kafkaContainer = new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.4.0"));

    /*
     * Override Spring Boot properties to point to the Testcontainers Kafka instance.
     * This ensures that when the application context starts, it connects to our test Kafka broker.
     */
    @DynamicPropertySource
    static void overrideProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.kafka.bootstrap-servers", kafkaContainer::getBootstrapServers);
        registry.add("spring.kafka.producer.key-deserializer", () -> "org.apache.kafka.common.serialization.StringDeserializer");
        registry.add("spring.kafka.producer.value-deserializer", () -> "org.springframework.kafka.support.serializer.JsonDeserializer");
        registry.add("spring.json.add.type.headers", () -> "false");

        // Consumer settings for the test listener
        registry.add("spring.kafka.consumer.group-id", () -> "test-group");
        registry.add("spring.kafka.consumer.auto-offset-reset", () -> "earliest");
        registry.add("spring.kafka.consumer.key-deserializer", () -> "org.apache.kafka.common.serialization.StringDeserializer");
        registry.add("spring.kafka.consumer.value-deserializer", () -> "org.springframework.kafka.support.serializer.JsonDeserializer");

        // JSON Specifics
        registry.add("spring.kafka.consumer.properties.spring.json.trusted.packages", () -> "*");
        // IMPORTANT: Point to the 'Message' class location in the Order service
        registry.add("spring.kafka.consumer.properties.spring.json.value.default.type", () -> "com.gorantla.orderservice.data.Message");
    }

}
