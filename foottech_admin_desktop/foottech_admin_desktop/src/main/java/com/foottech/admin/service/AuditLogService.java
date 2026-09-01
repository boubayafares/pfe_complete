package com.foottech.admin.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.type.CollectionType;
import com.foottech.admin.model.AuditLog;
import com.foottech.admin.network.ApiClient;

import java.util.List;

public class AuditLogService {
    private final ApiClient client;

    public AuditLogService(ApiClient client) {
        this.client = client;
    }

    public List<AuditLog> list() throws Exception {
        JsonNode page = client.get("/audit-logs/");
        CollectionType listType = client.mapper.getTypeFactory().constructCollectionType(List.class, AuditLog.class);
        return client.mapper.convertValue(page.get("results"), listType);
    }
}
