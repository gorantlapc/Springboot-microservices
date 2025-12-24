package com.gorantla.paymentservice.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/payment")
public class PaymentController {

    @PostMapping("/makePayment")
    public ResponseEntity<String> makePayment(@RequestBody String orderId) {
        // Simulate payment processing logic here
        return new ResponseEntity<>("Payment successful" + orderId, HttpStatus.OK);
    }
}
