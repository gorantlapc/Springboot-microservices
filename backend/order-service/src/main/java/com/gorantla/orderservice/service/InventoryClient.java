package com.gorantla.orderservice.service;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "inventory-service", path = "/api/inventory")
public interface InventoryClient {
    @GetMapping("/checkStock/{productCode}/{quantity}")
    boolean isInStock(
            @PathVariable("productCode") String productCode,
            @PathVariable("quantity") Integer quantity);
}
