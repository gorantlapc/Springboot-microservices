package com.gorantla.orderservice.controller;

import com.gorantla.orderservice.data.Message;
import com.gorantla.orderservice.data.Order;
import com.gorantla.orderservice.exception.ServiceUnavailableException;
import com.gorantla.orderservice.service.OrderService;
import io.dapr.client.DaprClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/order")
public class OrderController {

    @Value("${messaging.pubsub.name:pubsub}")
    private String pubSubName;

    @Value("${messaging.pubsub.topic:alerts}")
    private String topicName;

    private final DaprClient daprClient;

    private OrderService orderService;

    private static final Logger log = LoggerFactory.getLogger(OrderController.class);

    @Autowired
    public OrderController(DaprClient daprClient, OrderService orderService) {
        this.daprClient = daprClient;
        this.orderService = orderService;
    }

    @PostMapping("/execute")
    public Mono<String> executeOrder(@RequestBody Order order) {
        // Publish the event to the "orders" topic
        Mono<Message> message = orderService.processOrder(order);
        return daprClient.publishEvent(pubSubName, topicName, message.block())
                .thenReturn("Order Processed and Event Published")
                .onErrorResume(ex -> {
                    // Log the root cause and convert to ServiceUnavailableException so the GlobalExceptionHandler returns 503
                    log.error("Failed to publish event to Dapr pubsub ({}:{}). Cause: {}", pubSubName, topicName, ex.toString());
                    return Mono.error(new ServiceUnavailableException("Failed to publish event to pubsub", ex));
                });
    }

}
