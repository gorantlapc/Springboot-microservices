package com.gorantla.orderservice.data;

import java.math.BigDecimal;

public record PaymentResponse(String paymentId, String status, BigDecimal amount) {
}
