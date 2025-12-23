package com.gorantla.orderservice.controller;

import com.gorantla.orderservice.data.Message;
import com.gorantla.orderservice.data.Order;
import com.gorantla.orderservice.exception.ServiceUnavailableException;
import com.gorantla.orderservice.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/order")
public class OrderController {

    private OrderService orderService;

    @Autowired
    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @PostMapping("/process")
    public ResponseEntity<Message> processOrder(@RequestBody Order order) throws ServiceUnavailableException {
        Message response = orderService.processOrder(order);
        return ResponseEntity.ok(response);
    }

    @PostMapping
    public ResponseEntity<String> createOrder(@RequestBody Order order) {
        System.out.println("Order created: " + order.orderId());
        return ResponseEntity.ok("Order Created");
    }

    @PostMapping("/cancel")
    public ResponseEntity<String> cancelOrder(@RequestBody Order order) {
        System.out.println("Order canceled: " + order.orderId());
        return ResponseEntity.ok("Order Canceled");
    }
}
