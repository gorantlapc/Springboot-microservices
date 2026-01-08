package com.gorantla.inventoryservice.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/inventory")
public class InventoryController {

    private static final Logger log = LoggerFactory.getLogger(InventoryController.class);

    @GetMapping("/checkStock/{productCode}")
    public boolean isInStock(@PathVariable String productCode){

        log.info("Checking inventory for product code: {}", productCode);
        // Simulate inventory check logic here
        return true; // Assume the item is always in stock for this example
    }
}
