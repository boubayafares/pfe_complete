package com.foottech.admin.controller;

import com.foottech.admin.service.ServiceLocator;
import com.foottech.admin.util.SceneManager;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.control.Label;
import javafx.scene.layout.StackPane;

import java.io.IOException;
import java.util.Objects;

public class MainController {

    @FXML private StackPane contentArea;
    @FXML private Label adminNameLabel;
    @FXML private Label adminRoleLabel;

    private final ServiceLocator services = ServiceLocator.getInstance();
    private String currentView;

    /** Called by App right after this shell is loaded (populates the header, shows the dashboard). */
    public void init() {
        if (services.currentAdmin != null) {
            adminNameLabel.setText(services.currentAdmin.nomComplet());
            adminRoleLabel.setText(roleLabel(services.currentAdmin.role));
        }
        showDashboard();
    }

    private String roleLabel(String role) {
        return switch (role) {
            case "SUPER_ADMIN" -> "Super administrateur";
            case "MODERATEUR" -> "Modérateur";
            case "SUPPORT" -> "Support";
            default -> role;
        };
    }

    @FXML
    private void showDashboard() {
        load("/fxml/Dashboard.fxml", "dashboard");
    }

    @FXML
    private void showTeams() {
        load("/fxml/Teams.fxml", "teams");
    }

    @FXML
    private void showUsers() {
        load("/fxml/Users.fxml", "users");
    }

    @FXML
    private void showBroadcast() {
        load("/fxml/Broadcast.fxml", "broadcast");
    }

    @FXML
    private void showAuditLog() {
        load("/fxml/AuditLog.fxml", "auditlog");
    }

    @FXML
    private void refreshCurrentView() {
        if (currentView == null) return;
        switch (currentView) {
            case "dashboard" -> showDashboard();
            case "teams" -> showTeams();
            case "users" -> showUsers();
            case "broadcast" -> showBroadcast();
            case "auditlog" -> showAuditLog();
            default -> { /* no-op */ }
        }
    }

    @FXML
    private void handleLogout() {
        services.authService.logout();
        services.currentAdmin = null;
        LoginController controller = SceneManager.show("/fxml/Login.fxml", "FootTech Admin - Connexion", 480, 560);
        controller.setOnLoginSuccess(() -> {
            MainController shell = SceneManager.show("/fxml/Main.fxml", "FootTech Admin Console", 1200, 760);
            shell.init();
        });
    }

    private void load(String fxmlPath, String viewKey) {
        try {
            FXMLLoader loader = new FXMLLoader(Objects.requireNonNull(getClass().getResource(fxmlPath)));
            Parent view = loader.load();
            contentArea.getChildren().setAll(view);
            currentView = viewKey;
        } catch (IOException e) {
            throw new RuntimeException("Impossible de charger " + fxmlPath, e);
        }
    }
}
