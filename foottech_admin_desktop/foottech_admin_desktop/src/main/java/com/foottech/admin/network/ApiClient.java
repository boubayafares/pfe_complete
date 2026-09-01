package com.foottech.admin.network;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.foottech.admin.config.ApiConfig;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.locks.ReentrantLock;

/**
 * Thin HTTP client for the FootTech Admin Backend (Django/DRF).
 * Attaches the JWT access token to every request, and on a 401 transparently
 * refreshes the token once (serialized via a lock so concurrent 401s only
 * trigger a single refresh call) before retrying.
 */
public class ApiClient {
    private final HttpClient http = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();
    public final ObjectMapper mapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE)
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

    private final TokenStore tokenStore;
    private final ReentrantLock refreshLock = new ReentrantLock();

    public ApiClient(TokenStore tokenStore) {
        this.tokenStore = tokenStore;
    }

    public JsonNode get(String path) {
        return execute("GET", path, null, true);
    }

    public JsonNode post(String path, Object body) {
        return execute("POST", path, body, true);
    }

    public JsonNode patch(String path, Object body) {
        return execute("PATCH", path, body, true);
    }

    /** Used only for /auth/login/ and /auth/refresh/, which must not attach a (possibly stale) token. */
    public JsonNode postPublic(String path, Object body) {
        return execute("POST", path, body, false);
    }

    private JsonNode execute(String method, String path, Object body, boolean authenticated) {
        try {
            return doExecute(method, path, body, authenticated, false);
        } catch (ApiException e) {
            if (authenticated && e.isUnauthorized() && tryRefresh()) {
                return doExecute(method, path, body, true, true); // single retry after refresh
            }
            throw e;
        }
    }

    private JsonNode doExecute(String method, String path, Object body, boolean authenticated, boolean isRetry) {
        try {
            String url = ApiConfig.baseUrl() + path;
            HttpRequest.Builder builder = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .header("Content-Type", "application/json")
                    .header("Accept", "application/json")
                    .timeout(Duration.ofSeconds(15));

            if (authenticated && tokenStore.accessToken() != null) {
                builder.header("Authorization", "Bearer " + tokenStore.accessToken());
            }

            HttpRequest.BodyPublisher publisher = body == null
                    ? HttpRequest.BodyPublishers.noBody()
                    : HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(body));

            switch (method) {
                case "GET" -> builder.GET();
                case "POST" -> builder.POST(publisher);
                case "PATCH" -> builder.method("PATCH", publisher);
                default -> throw new IllegalArgumentException("Unsupported method: " + method);
            }

            HttpResponse<String> response = http.send(builder.build(), HttpResponse.BodyHandlers.ofString());
            int status = response.statusCode();

            if (status >= 200 && status < 300) {
                String responseBody = response.body();
                return (responseBody == null || responseBody.isBlank()) ? mapper.createObjectNode() : mapper.readTree(responseBody);
            }

            String message = extractError(response.body());
            throw new ApiException(message, status);
        } catch (IOException | InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ApiException("Impossible de contacter le serveur admin (" + ApiConfig.baseUrl() + ")", e);
        }
    }

    private String extractError(String body) {
        try {
            JsonNode node = mapper.readTree(body);
            if (node.has("detail")) return node.get("detail").asText();
            if (node.has("error")) return node.get("error").asText();
            return node.toString();
        } catch (Exception ignored) {
            return "Erreur inconnue";
        }
    }

    private boolean tryRefresh() {
        refreshLock.lock();
        try {
            if (tokenStore.refreshToken() == null) return false;
            JsonNode result = doExecute(
                    "POST", "/auth/refresh/",
                    Map.of("refresh", tokenStore.refreshToken()),
                    false, false
            );
            if (result.has("access")) {
                if (result.has("refresh")) {
                    // ROTATE_REFRESH_TOKENS + BLACKLIST_AFTER_ROTATION are enabled server-side:
                    // the old refresh token is now blacklisted, so we must persist the new one.
                    tokenStore.save(result.get("access").asText(), result.get("refresh").asText());
                } else {
                    tokenStore.updateAccessToken(result.get("access").asText());
                }
                return true;
            }
            return false;
        } catch (ApiException e) {
            tokenStore.clear();
            return false;
        } finally {
            refreshLock.unlock();
        }
    }
}
