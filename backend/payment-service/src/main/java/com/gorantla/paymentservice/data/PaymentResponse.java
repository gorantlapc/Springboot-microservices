package com.gorantla.paymentservice.data;

public record PaymentResponse(String paymentId, String status, java.math.BigDecimal amount) {
}
