package integration;

import com.gorantla.orderservice.OrderServiceApplication;
import com.gorantla.orderservice.data.Message;
import com.gorantla.orderservice.data.Order;
import com.gorantla.orderservice.data.OrderStatus;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.kafka.core.KafkaTemplate;
import org.testcontainers.shaded.org.awaitility.Awaitility;

import java.math.BigDecimal;
import java.time.Duration;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * This test class is an integration test for the Kafka messaging in the Order Service.
 * It uses Spring Boot's testing support to load the application context and autowire the necessary components.
 * The test sends a message to a Kafka topic and then asserts that the KafkaConsumer has received it.
 */
@SpringBootTest(classes = OrderServiceApplication.class)
@Import(KafkaConsumer.class)
public class OrderServiceKafkaIntegrationTest extends BaseKafkaIntegrationTest {

    @Autowired
    KafkaTemplate<String, Message> kafkaTemplate;

    @Autowired
    KafkaConsumer kafkaConsumer;

    /*
     * This test sends a message to the Kafka topic and then asserts that the KafkaConsumer
     * has received it.
     */
    @Test
    void testKafkaSend() {
        kafkaTemplate.send("email-events",
                new Message(OrderStatus.ORDER_CREATED,
                        new Order("1234", "abc", "2345", 3, BigDecimal.valueOf(100))));

        // Assert (using Awaitility to handle the async nature of Kafka)
        Awaitility.await()
                .atMost(Duration.ofSeconds(5))
                .untilAsserted(() -> {
                    assertTrue(
                            kafkaConsumer.getReceivedOrders()
                                    .contains("1234"));
                });
    }

}
