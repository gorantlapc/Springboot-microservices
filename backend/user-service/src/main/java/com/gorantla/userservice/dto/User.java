package com.gorantla.userservice.dto;

import java.util.Objects;

public final class User {
    private final String userId;

    private transient String password;

    private final String name;
    private final String address;
    private final int mobile;

    public User(String userId, String name, String address, int mobile) {
        this.userId = userId;
        this.name = name;
        this.address = address;
        this.mobile = mobile;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String userId() {
        return userId;
    }

    public String name() {
        return name;
    }

    public String address() {
        return address;
    }

    public int mobile() {
        return mobile;
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == this) return true;
        if (obj == null || obj.getClass() != this.getClass()) return false;
        var that = (User) obj;
        return Objects.equals(this.userId, that.userId) &&
                Objects.equals(this.name, that.name) &&
                Objects.equals(this.address, that.address) &&
                this.mobile == that.mobile;
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId, name, address, mobile);
    }

    @Override
    public String toString() {
        return "User[" +
                "userId=" + userId + ", " +
                "name=" + name + ", " +
                "address=" + address + ", " +
                "mobile=" + mobile + ']';
    }

}
