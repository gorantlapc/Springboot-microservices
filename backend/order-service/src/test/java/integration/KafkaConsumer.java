package integration;

import com.gorantla.orderservice.data.Message;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

@Component
public class KafkaConsumer {
    private final List<String> receivedOrders = new CopyOnWriteArrayList<>();

    @KafkaListener(topics = "email-events", groupId = "test-group")
    public void consumeEmailEvent(Message message) {
        receivedOrders.add(message.orderRequest().orderId());
    }

    public List<String> getReceivedOrders() {
        return receivedOrders;
    }
}
