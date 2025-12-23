package com.gorantla.userservice.controller;

import com.gorantla.userservice.dto.User;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping("/greet/{message}")
    public String greet(@PathVariable String message) {
        return "Hi " + message;
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
