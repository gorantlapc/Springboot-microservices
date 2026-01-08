package com.gorantla.notificationservice.controller;

import com.gorantla.notificationservice.component.MailSender;
import com.gorantla.notificationservice.data.Message;
import io.dapr.Topic;
import io.dapr.client.domain.CloudEvent;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
public class OrderSubscriber {

    private final MailSender mailSender;

    public OrderSubscriber(MailSender mailSender) {
        this.mailSender = mailSender;
    }

    @Topic(name = "alerts", pubsubName = "my-pubsub")
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
