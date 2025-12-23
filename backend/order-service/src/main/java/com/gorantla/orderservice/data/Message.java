package com.gorantla.orderservice.data;

public record Message(OrderStatus orderStatus, Order orderRequest) {
}
