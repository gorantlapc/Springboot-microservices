package com.gorantla.orderservice.service;

import com.gorantla.orderservice.data.Message;
import com.gorantla.orderservice.data.Order;
import com.gorantla.orderservice.data.OrderStatus;
import com.gorantla.orderservice.data.PaymentResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

@Service
public class OrderService {

    private static final Logger log = LoggerFactory.getLogger(OrderService.class);

    private final PaymentClient paymentClient;

    private final InventoryClient inventoryClient;

    public OrderService(PaymentClient paymentClient, InventoryClient inventoryClient) {
        this.paymentClient = paymentClient;
        this.inventoryClient = inventoryClient;
    }

    public Mono<Message> processOrder(Order order) {

        log.debug("Processing order: {}", order);
        // Call the inventory service to check and reserve stock
        return inventoryClient.isInStock(order.productCode()).flatMap(isInStock -> {
            if (Boolean.FALSE.equals(isInStock)) {
                return Mono.error(new IllegalStateException("Product is out of stock: " + order.productCode()));
            }

            // Call the payment service to make a payment for the order
            return Mono.fromCallable(() -> {
                PaymentResponse paymentResponse = paymentClient.processPayment(order);
                log.info("Payment service response: {} with {}", paymentResponse.status(), paymentResponse.paymentId());
                return new Message(OrderStatus.ORDER_CREATED, order);
            }).subscribeOn(Schedulers.boundedElastic());
        }).doOnNext(msg -> log.debug(String.valueOf(msg)));

    }

}
