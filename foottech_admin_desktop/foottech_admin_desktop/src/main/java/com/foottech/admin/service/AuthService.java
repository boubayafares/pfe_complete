package com.foottech.admin.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.foottech.admin.model.Administrateur;
import com.foottech.admin.network.ApiClient;
import com.foottech.admin.network.TokenStore;

import java.util.Map;

public class AuthService {
    private final ApiClient client;
    private final TokenStore tokenStore;

    public AuthService(ApiClient client, TokenStore tokenStore) {
        this.client = client;
        this.tokenStore = tokenStore;
    }

    /** Authenticates and persists the access/refresh tokens. Returns the logged-in administrator. */
    public Administrateur login(String email, String password) throws Exception {
        JsonNode result = client.postPublic("/auth/login/", Map.of("email", email, "password", password));
        tokenStore.save(result.get("access").asText(), result.get("refresh").asText());
        return client.mapper.treeToValue(result.get("administrateur"), Administrateur.class);
    }

    public Administrateur me() throws Exception {
        JsonNode result = client.get("/auth/me/");
        return client.mapper.treeToValue(result, Administrateur.class);
    }

    public void changePassword(String ancien, String nouveau) {
        client.post("/auth/change-password/", Map.of(
                "ancien_mot_de_passe", ancien,
                "nouveau_mot_de_passe", nouveau
        ));
    }

    public void logout() {
        tokenStore.clear();
    }

    public boolean hasSession() {
        return tokenStore.hasSession();
    }
}
