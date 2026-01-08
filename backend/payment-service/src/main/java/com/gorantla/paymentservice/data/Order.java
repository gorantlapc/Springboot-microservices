package com.gorantla.paymentservice.data;

import java.math.BigDecimal;

public record Order(String orderId, String userEmail, String productCode, int quantity, BigDecimal price) {
}
