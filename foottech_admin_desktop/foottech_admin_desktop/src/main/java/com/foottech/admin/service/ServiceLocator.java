package com.foottech.admin.service;

import com.foottech.admin.model.Administrateur;
import com.foottech.admin.network.ApiClient;
import com.foottech.admin.network.TokenStore;

/**
 * Simple hand-rolled service locator (no DI framework needed for an app this
 * size) shared across every controller via {@link #getInstance()}.
 */
public final class ServiceLocator {
    private static final ServiceLocator INSTANCE = new ServiceLocator();

    public final TokenStore tokenStore;
    public final ApiClient apiClient;
    public final AuthService authService;
    public final DashboardService dashboardService;
    public final TeamsService teamsService;
    public final UsersService usersService;
    public final AuditLogService auditLogService;
    public final BroadcastService broadcastService;

    /** Set once after a successful login/me call; readable by every screen (e.g. to gate super-admin actions). */
    public Administrateur currentAdmin;

    private ServiceLocator() {
        this.tokenStore = new TokenStore();
        this.apiClient = new ApiClient(tokenStore);
        this.authService = new AuthService(apiClient, tokenStore);
        this.dashboardService = new DashboardService(apiClient);
        this.teamsService = new TeamsService(apiClient);
        this.usersService = new UsersService(apiClient);
        this.auditLogService = new AuditLogService(apiClient);
        this.broadcastService = new BroadcastService(apiClient);
    }

    public static ServiceLocator getInstance() {
        return INSTANCE;
    }

    public boolean isSuperAdmin() {
        return currentAdmin != null && "SUPER_ADMIN".equals(currentAdmin.role);
    }
}
