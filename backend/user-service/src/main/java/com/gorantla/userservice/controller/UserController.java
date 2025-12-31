package com.gorantla.userservice.controller;

import com.gorantla.userservice.dto.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private static final Logger log = LoggerFactory.getLogger(UserController.class);

    @GetMapping("/greet/{message}")
    public ResponseEntity<String> greet(@PathVariable String message) {
        log.debug("Greet endpoint called with message: {}", message);
        return ResponseEntity.ok("Hi " + message);
    }

    @PostMapping("/register")
    public String registerUser(@RequestBody User userInfo) {
        return "User registered successfully";
    }

    @PutMapping("/update")
    public String updateUser(@RequestBody User userInfo) {
        return "User updated successfully";
    }
}
