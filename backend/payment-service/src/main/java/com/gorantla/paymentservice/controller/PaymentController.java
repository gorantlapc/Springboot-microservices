package com.gorantla.paymentservice.controller;

import com.gorantla.paymentservice.data.Order;
import com.gorantla.paymentservice.data.PaymentResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/payment")
public class PaymentController {

    private static final Logger log = LoggerFactory.getLogger(PaymentController.class);

    @PostMapping("/makePayment")
    public ResponseEntity<PaymentResponse> makePayment(@RequestBody Order order) {
        // Simulate payment processing logic here
        log.info("Processing payment for order ID: {}", order.orderId());
        return ResponseEntity.ok(new PaymentResponse("TX123", "Success", order.price()));
    }
}
