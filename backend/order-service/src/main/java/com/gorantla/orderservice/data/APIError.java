package com.gorantla.orderservice.data;

import java.time.Instant;

public record APIError(
        String message,
        String errorCode,
        Instant timestamp) {
}
