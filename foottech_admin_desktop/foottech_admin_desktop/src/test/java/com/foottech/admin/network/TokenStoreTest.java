package com.foottech.admin.network;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class TokenStoreTest {
    @Test
    void storesAndClearsTokensInMemory() {
        TokenStore store = new TokenStore();

        store.save("access", "refresh");
        assertTrue(store.hasSession());
        assertEquals("access", store.accessToken());
        assertEquals("refresh", store.refreshToken());

        store.updateAccessToken("new-access");
        assertEquals("new-access", store.accessToken());

        store.clear();
        assertFalse(store.hasSession());
        assertNull(store.accessToken());
        assertNull(store.refreshToken());
    }

    @Test
    void doesNotPersistTokensAcrossInstances() {
        TokenStore first = new TokenStore();
        first.save("access", "refresh");

        TokenStore second = new TokenStore();
        assertFalse(second.hasSession());
        assertNull(second.accessToken());
        assertNull(second.refreshToken());
    }
}
