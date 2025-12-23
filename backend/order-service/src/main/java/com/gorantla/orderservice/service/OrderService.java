package com.gorantla.orderservice.service;

import com.gorantla.orderservice.data.Message;
import com.gorantla.orderservice.data.Order;
import com.gorantla.orderservice.data.OrderStatus;
import com.gorantla.orderservice.exception.ServiceUnavailableException;
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

    private final RestTemplate restTemplate;

    private final KafkaProducer kafkaProducer;

    public OrderService(RestTemplate restTemplate, KafkaProducer kafkaProducer) {
        this.restTemplate = restTemplate;
        this.kafkaProducer = kafkaProducer;
    }

    @CircuitBreaker(name = "myCircuitBreaker", fallbackMethod = "fallbackMethod")
    public Message processOrder(Order order) {

        // Call the payment service to make a payment for the order
        String message = restTemplate.postForObject(
                paymentServiceUrl + "/payment/makePayment",
                order.orderId(),
                String.class
        );

        Message kafkaMessage = new Message(OrderStatus.ORDER_CREATED, order);
        // Verify payment success from the response message and send message to Kafka only if successful
        if (message != null && message.contains("Payment successful")) {
            kafkaProducer.sendMessage("email-events", kafkaMessage);
        }

        return kafkaMessage;
    }

    public String fallbackMethod(Throwable throwable) {
        System.out.println("circuit breaker message " + throwable.getMessage());
        if (throwable instanceof ResourceAccessException || throwable instanceof CallNotPermittedException
                || throwable instanceof HttpServerErrorException) {
            System.out.println("Payment service is down or unreachable.");
            throw new ServiceUnavailableException("Payment service is currently unavailable.", throwable);
        }
        throw new ServiceUnavailableException("Payment service is currently unavailable.", throwable);
    }
}
