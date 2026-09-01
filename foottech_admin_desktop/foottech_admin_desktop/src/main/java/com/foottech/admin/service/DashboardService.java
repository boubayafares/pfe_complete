package com.foottech.admin.service;

import com.foottech.admin.model.DashboardStats;
import com.foottech.admin.network.ApiClient;

public class DashboardService {
    private final ApiClient client;

    public DashboardService(ApiClient client) {
        this.client = client;
    }

    public DashboardStats fetch() throws Exception {
        return client.mapper.treeToValue(client.get("/dashboard/"), DashboardStats.class);
    }
}
