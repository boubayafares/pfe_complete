package com.foottech.admin.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.type.CollectionType;
import com.foottech.admin.model.Equipe;
import com.foottech.admin.model.Joueur;
import com.foottech.admin.network.ApiClient;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

public class TeamsService {
    private final ApiClient client;

    public TeamsService(ApiClient client) {
        this.client = client;
    }

    public List<Equipe> list(String search, Boolean actif) throws Exception {
        StringBuilder path = new StringBuilder("/teams/?");
        if (search != null && !search.isBlank()) {
            path.append("search=").append(URLEncoder.encode(search, StandardCharsets.UTF_8)).append("&");
        }
        if (actif != null) {
            path.append("actif=").append(actif).append("&");
        }
        JsonNode page = client.get(path.toString());
        CollectionType listType = client.mapper.getTypeFactory().constructCollectionType(List.class, Equipe.class);
        return client.mapper.convertValue(page.get("results"), listType);
    }

    public List<Joueur> players(long idEquipe) throws Exception {
        JsonNode page = client.get("/teams/" + idEquipe + "/players/");
        CollectionType listType = client.mapper.getTypeFactory().constructCollectionType(List.class, Joueur.class);
        return client.mapper.convertValue(page.get("results"), listType);
    }

    public Equipe suspend(long idEquipe, String raison) throws Exception {
        JsonNode result = client.post("/teams/" + idEquipe + "/suspend/", Map.of("raison", raison == null ? "" : raison));
        return client.mapper.treeToValue(result, Equipe.class);
    }

    public Equipe activate(long idEquipe, String raison) throws Exception {
        JsonNode result = client.post("/teams/" + idEquipe + "/activate/", Map.of("raison", raison == null ? "" : raison));
        return client.mapper.treeToValue(result, Equipe.class);
    }
}
