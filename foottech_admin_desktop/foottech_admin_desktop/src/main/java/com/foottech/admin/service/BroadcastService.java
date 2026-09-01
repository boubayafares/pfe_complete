package com.foottech.admin.service;

import com.foottech.admin.network.ApiClient;

import java.util.Map;

public class BroadcastService {
    private final ApiClient client;

    public BroadcastService(ApiClient client) {
        this.client = client;
    }

    /** Returns the number of recipients the notification was sent to. */
    public int send(String message, String cibleRole) {
        var result = client.post("/broadcast/", Map.of("message", message, "cible_role", cibleRole));
        return result.get("destinataires").asInt();
    }
}
