package com.gorantla.orderservice.controller;

import com.gorantla.orderservice.data.Message;
import com.gorantla.orderservice.data.Order;
import com.gorantla.orderservice.exception.ServiceUnavailableException;
import com.gorantla.orderservice.service.OrderService;
import io.dapr.client.DaprClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/order")
public class OrderController {

    private static final String PUBSUB_NAME = "my-pubsub"; // Matches YAML name
    private static final String TOPIC_NAME = "alerts";
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
        Message message = orderService.processOrder(order);
        return daprClient.publishEvent(PUBSUB_NAME, TOPIC_NAME, message)
                .thenReturn("Order Processed and Event Published")
                .onErrorResume(ex -> {
                    // Log the root cause and convert to ServiceUnavailableException so the GlobalExceptionHandler returns 503
                    log.error("Failed to publish event to Dapr pubsub ({}:{}). Cause: {}", PUBSUB_NAME, TOPIC_NAME, ex.toString());
                    return Mono.error(new ServiceUnavailableException("Failed to publish event to pubsub",ex));
                });
    }

}
