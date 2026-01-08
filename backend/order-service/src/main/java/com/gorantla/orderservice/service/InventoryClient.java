package com.gorantla.orderservice.service;

import io.dapr.client.DaprClient;
import io.dapr.client.domain.HttpExtension;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

@Service
public class InventoryClient {

    private final DaprClient daprClient;

    public InventoryClient(DaprClient daprClient) {
        this.daprClient = daprClient;
    }

    public Mono<Boolean> isInStock(String productCode) {
        // "inventory-service" is the Dapr app-id of the target microservice
        // "/api/inventory/checkStock/" is the endpoint path in that microservice
        return daprClient.invokeMethod("inventory-service", "/api/inventory/checkStock/" + productCode,
                null, HttpExtension.GET, Boolean.class);
    }
}
