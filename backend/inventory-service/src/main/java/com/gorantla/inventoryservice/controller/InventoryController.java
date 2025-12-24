package com.gorantla.inventoryservice.controller;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/inventory")
public class InventoryController {

    @GetMapping("/checkStock/{productCode}/{quantity}")
    public boolean isInStock(@PathVariable String productCode, @PathVariable int quantity) {
        // Simulate inventory check logic here
        return true; // Assume the item is always in stock for this example
    }
}
