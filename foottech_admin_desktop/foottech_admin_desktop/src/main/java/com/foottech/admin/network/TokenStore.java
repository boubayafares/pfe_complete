package com.foottech.admin.network;

import java.util.prefs.Preferences;

/**
 * Persists the JWT access/refresh tokens across app restarts using the
 * platform-native preferences store (Windows Registry, macOS plist,
 * Linux dconf/XML) - no plaintext file on disk.
 */
public final class TokenStore {
    private static final Preferences PREFS = Preferences.userNodeForPackage(TokenStore.class);
    private static final String ACCESS_KEY = "access_token";
    private static final String REFRESH_KEY = "refresh_token";

    private String accessToken;
    private String refreshToken;

    public TokenStore() {
        this.accessToken = PREFS.get(ACCESS_KEY, null);
        this.refreshToken = PREFS.get(REFRESH_KEY, null);
    }

    public void save(String accessToken, String refreshToken) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        PREFS.put(ACCESS_KEY, accessToken);
        PREFS.put(REFRESH_KEY, refreshToken);
    }

    public void updateAccessToken(String accessToken) {
        this.accessToken = accessToken;
        PREFS.put(ACCESS_KEY, accessToken);
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
        PREFS.remove(ACCESS_KEY);
        PREFS.remove(REFRESH_KEY);
    }
}
