package com.gorantla.notificationservice.controller;

import com.gorantla.notificationservice.component.MailSender;
import com.gorantla.notificationservice.data.Message;
import io.dapr.client.domain.CloudEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
public class OrderSubscriber {

    @Value("${messaging.pubsub.name:pubsub}")
    private String pubSubName;

    @Value("${messaging.pubsub.topic:alerts}")
    private String topicName;

    private final MailSender mailSender;

    public OrderSubscriber(MailSender mailSender) {
        this.mailSender = mailSender;
    }

    // Dapr will call GET /dapr/subscribe to discover subscriptions at runtime.
    @GetMapping(path = "/dapr/subscribe")
    public List<Map<String, String>> subscriptions() {
        Map<String, String> sub = new HashMap<>();
        sub.put("pubsubname", pubSubName);
        sub.put("topic", topicName);
        // route should match the path of the POST endpoint below (without leading slash)
        sub.put("route", "process-alerts");
        return Collections.singletonList(sub);
    }

    @PostMapping(path = "/process-alerts")
    public Mono<Void> handleEvents(@RequestBody CloudEvent<Message> orderEvent) {
        // Implementation for subscribing to order events
        Message message= orderEvent.getData();
        switch (message.orderStatus()) {
            case ORDER_CREATED -> mailSender.sendEmail(message.orderRequest().userEmail(),
                    "Order Notification",
                    "Your order with ID " + message.orderRequest().orderId() + " with " + message.orderRequest().price() + " has been processed.");
            case ORDER_CANCELLED -> mailSender.sendEmail(message.orderRequest().userEmail(),
                    "Order Cancellation",
                    "Your order with ID " + message.orderRequest().orderId() + " has been cancelled.");
            case ORDER_UPDATED -> System.out.println("Received email event from Kafka");
            default -> System.out.println("Unknown event type: " + message.orderStatus());
        }
        return Mono.empty();
    }
}
