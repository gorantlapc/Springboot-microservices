package com.gorantla.orderservice.service;

import com.gorantla.orderservice.data.Message;
import com.gorantla.orderservice.data.Order;
import com.gorantla.orderservice.data.OrderStatus;
import com.gorantla.orderservice.exception.ServiceUnavailableException;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

@Service
public class OrderService {

    private static final Logger log = LoggerFactory.getLogger(OrderService.class);
    @Value("${payment.service.url}")
    private String paymentServiceUrl;

    private final RestTemplate restTemplate;

    private final InventoryClient inventoryClient;

    public OrderService(RestTemplate restTemplate, InventoryClient inventoryClient) {
        this.restTemplate = restTemplate;
        this.inventoryClient = inventoryClient;
    }

    @CircuitBreaker(name = "myCircuitBreaker", fallbackMethod = "fallbackMethod")
    public Message processOrder(Order order) {
        log.debug("Processing order: {}", order);
        // Call the inventory service to check and reserve stock
        boolean isInStock = inventoryClient.isInStock(order.productCode(), order.quantity());
        if (!isInStock) {
            throw new IllegalStateException("Product is out of stock: " + order.productCode());
        }

        // Call the payment service to make a payment for the order
        String message = restTemplate.postForObject(
                paymentServiceUrl + "/api/payment/makePayment",
                order.orderId(),
                String.class
        );

        Message topicMessage = new Message(OrderStatus.ORDER_CREATED, order);

        log.debug(String.valueOf(topicMessage));
        return topicMessage;
    }

    public String fallbackMethod(Throwable throwable) {
        if (throwable instanceof ResourceAccessException || throwable instanceof CallNotPermittedException
                || throwable instanceof HttpServerErrorException) {
            throw new ServiceUnavailableException("Payment service is currently unavailable.", throwable);
        }
        throw new ServiceUnavailableException("Payment service is currently unavailable.", throwable);
    }
}
