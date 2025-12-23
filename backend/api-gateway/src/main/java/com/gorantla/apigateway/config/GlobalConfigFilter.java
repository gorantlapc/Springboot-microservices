package com.gorantla.apigateway.config;

import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.http.server.reactive.ServerHttpRequest;

@Configuration
public class GlobalConfigFilter {

    @Bean
    @Order(Ordered.HIGHEST_PRECEDENCE)
    public GlobalFilter logRequestData() {
        return (exchange, chain) -> {
            ServerHttpRequest request = exchange.getRequest();

            System.out.println("=== Incoming Request ===");
            System.out.println("Method: " + request.getMethod());
            System.out.println("URI: " + request.getURI());

            HttpHeaders headers = request.getHeaders();
            headers.forEach((name, values) ->
                    System.out.println(name + ": " + String.join(", ", values))
            );
            System.out.println("========================");

            return chain.filter(exchange);
        };
    }

}
