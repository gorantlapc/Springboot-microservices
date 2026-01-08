package com.gorantla.orderservice.service;

import com.gorantla.orderservice.data.Order;
import com.gorantla.orderservice.data.PaymentResponse;
import io.dapr.client.DaprClient;
import io.dapr.client.domain.HttpExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

@Service
public class PaymentClient {
    private final DaprClient daprClient;

    public PaymentClient(DaprClient daprClient) {
        this.daprClient = daprClient;
    }

    public PaymentResponse processPayment(Order order) {
        return daprClient.invokeMethod("payment-service", "/api/payment/makePayment", order, HttpExtension.POST, PaymentResponse.class).block();
    }
}
