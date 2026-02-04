package com.gorantla.orderservice.service;

import com.gorantla.orderservice.data.Message;
import com.gorantla.orderservice.data.Order;
import com.gorantla.orderservice.data.OrderStatus;
import com.gorantla.orderservice.exception.ServiceUnavailableException;
import io.awspring.cloud.sns.core.SnsTemplate;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

@Service
public class OrderService {

    @Value("${payment.service.url}")
    private String paymentServiceUrl;

    @Value("${sns.topic.arn}")
    private String topicArn;

    private final RestTemplate restTemplate;

    private final InventoryClient inventoryClient;

    private final SnsTemplate snsTemplate;

    public OrderService(RestTemplate restTemplate, InventoryClient inventoryClient, SnsTemplate snsTemplate) {
        this.restTemplate = restTemplate;
        this.inventoryClient = inventoryClient;
        this.snsTemplate = snsTemplate;
    }

    @CircuitBreaker(name = "myCircuitBreaker", fallbackMethod = "fallbackMethod")
    public Message processOrder(Order order) {
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

        Message snsMessage = new Message(OrderStatus.ORDER_CREATED, order);
        // Verify payment success from the response message and send message to SNS only if successful
        if (message != null && message.contains("Payment successful")) {
            if (topicArn == null || topicArn.isBlank()) {
                throw new IllegalStateException("SNS topic ARN is not configured: AWS_SNS_TOPIC_ARN must be provided");
            }
            try {
                snsTemplate.convertAndSend(topicArn, snsMessage);
            } catch (Exception ex) {
                throw new RuntimeException("Failed to publish message to SNS topic " + topicArn, ex);
            }
        } else {
            throw new IllegalStateException("Payment failed for order: " + order.orderId());
        }

        return snsMessage;
    }

    public String fallbackMethod(Throwable throwable) {
        if (throwable instanceof ResourceAccessException || throwable instanceof CallNotPermittedException
                || throwable instanceof HttpServerErrorException) {
            throw new ServiceUnavailableException("Payment service is currently unavailable.", throwable);
        }
        throw new ServiceUnavailableException("Payment service is currently unavailable.", throwable);
    }
}
