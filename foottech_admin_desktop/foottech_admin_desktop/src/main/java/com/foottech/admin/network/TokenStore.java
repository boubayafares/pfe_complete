package com.foottech.admin.network;

/**
 * Keeps JWT access/refresh tokens in process memory only.
 *
 * Java Preferences is not an encrypted credential store and previously left
 * reusable refresh tokens readable in the registry/plist/XML store. Requiring
 * a new login after an application restart is the safer cross-platform default.
 */
public final class TokenStore {
    private String accessToken;
    private String refreshToken;

    public void save(String accessToken, String refreshToken) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
    }

    public void updateAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }

    public String accessToken() {
        return accessToken;
    }

    public String refreshToken() {
        return refreshToken;
    }

    public boolean hasSession() {
        return accessToken != null && refreshToken != null;
    }

    public void clear() {
        accessToken = null;
        refreshToken = null;
    }
}
