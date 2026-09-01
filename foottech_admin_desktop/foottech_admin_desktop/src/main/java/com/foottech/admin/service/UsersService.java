package com.foottech.admin.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.type.CollectionType;
import com.foottech.admin.model.Utilisateur;
import com.foottech.admin.network.ApiClient;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

public class UsersService {
    private final ApiClient client;

    public UsersService(ApiClient client) {
        this.client = client;
    }

    public List<Utilisateur> list(String search, String role, Boolean actif) throws Exception {
        StringBuilder path = new StringBuilder("/users/?");
        if (search != null && !search.isBlank()) {
            path.append("search=").append(URLEncoder.encode(search, StandardCharsets.UTF_8)).append("&");
        }
        if (role != null && !role.isBlank() && !role.equals("TOUS")) {
            path.append("role=").append(role).append("&");
        }
        if (actif != null) {
            path.append("actif=").append(actif).append("&");
        }
        JsonNode page = client.get(path.toString());
        CollectionType listType = client.mapper.getTypeFactory().constructCollectionType(List.class, Utilisateur.class);
        return client.mapper.convertValue(page.get("results"), listType);
    }

    public Utilisateur suspend(long idUtilisateur, String raison) throws Exception {
        JsonNode result = client.post("/users/" + idUtilisateur + "/suspend/", Map.of("raison", raison == null ? "" : raison));
        return client.mapper.treeToValue(result, Utilisateur.class);
    }

    public Utilisateur activate(long idUtilisateur, String raison) throws Exception {
        JsonNode result = client.post("/users/" + idUtilisateur + "/activate/", Map.of("raison", raison == null ? "" : raison));
        return client.mapper.treeToValue(result, Utilisateur.class);
    }
}
