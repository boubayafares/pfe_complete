package com.foottech.admin.config;

/**
 * Base URL of the FootTech Admin Backend (Django). Override at launch with:
 * {@code java -jar foottech-admin-desktop.jar --api.baseUrl=https://admin-api.foottech.app/api/admin}
 * or the FOOTTECH_ADMIN_API_URL environment variable.
 */
public final class ApiConfig {
    private ApiConfig() {}

    private static String baseUrl = resolveDefault();

    private static String resolveDefault() {
        String env = System.getenv("FOOTTECH_ADMIN_API_URL");
        if (env != null && !env.isBlank()) return env;
        String prop = System.getProperty("api.baseUrl");
        if (prop != null && !prop.isBlank()) return prop;
        return "http://localhost:8000/api/admin";
    }

    public static String baseUrl() {
        return baseUrl;
    }

    public static void setBaseUrl(String url) {
        baseUrl = url;
    }
}
