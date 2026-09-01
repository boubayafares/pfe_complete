package com.foottech.admin.controller;

import com.foottech.admin.model.DashboardStats;
import com.foottech.admin.service.ServiceLocator;
import com.foottech.admin.util.AlertUtil;
import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressIndicator;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.scene.layout.VBox;

public class DashboardController {

    @FXML private ProgressIndicator loadingIndicator;
    @FXML private VBox content;
    @FXML private HBox statCardsRow;
    @FXML private VBox roleBreakdownBox;

    private final ServiceLocator services = ServiceLocator.getInstance();

    @FXML
    private void initialize() {
        loadStats();
    }

    private void loadStats() {
        new Thread(() -> {
            try {
                DashboardStats stats = services.dashboardService.fetch();
                Platform.runLater(() -> render(stats));
            } catch (Exception e) {
                Platform.runLater(() -> {
                    loadingIndicator.setVisible(false);
                    AlertUtil.error("Impossible de charger le tableau de bord : " + e.getMessage());
                });
            }
        }, "dashboard-load").start();
    }

    private void render(DashboardStats stats) {
        loadingIndicator.setVisible(false);
        loadingIndicator.setManaged(false);
        content.setVisible(true);
        content.setManaged(true);

        statCardsRow.getChildren().setAll(
                statCard("Équipes", String.valueOf(stats.equipes.total),
                        stats.equipes.suspendues + " suspendue(s)"),
                statCard("Utilisateurs", String.valueOf(stats.utilisateurs.total),
                        stats.utilisateurs.actifs + " actif(s)"),
                statCard("Joueurs", String.valueOf(stats.joueurs.total),
                        stats.joueurs.enAttenteActivation + " en attente d'activation"),
                statCard("Matchs ce mois", String.valueOf(stats.activite.matchsCeMois),
                        stats.activite.entrainementsAVenir + " entraînement(s) à venir")
        );

        roleBreakdownBox.getChildren().clear();
        if (stats.utilisateurs.parRole != null) {
            for (DashboardStats.RoleCount rc : stats.utilisateurs.parRole) {
                HBox row = new HBox(8);
                row.setAlignment(Pos.CENTER_LEFT);
                Label roleLabel = new Label(rc.role);
                roleLabel.getStyleClass().add("role-label");
                Label countLabel = new Label(String.valueOf(rc.total));
                countLabel.getStyleClass().add("role-count");
                HBox spacer = new HBox();
                HBox.setHgrow(spacer, Priority.ALWAYS);
                row.getChildren().addAll(roleLabel, spacer, countLabel);
                roleBreakdownBox.getChildren().add(row);
            }
        }
    }

    private VBox statCard(String label, String value, String subtitle) {
        VBox card = new VBox(4);
        card.getStyleClass().add("stat-card");
        card.setPadding(new Insets(16));
        HBox.setHgrow(card, Priority.ALWAYS);

        Label valueLabel = new Label(value);
        valueLabel.getStyleClass().add("stat-value");
        Label titleLabel = new Label(label);
        titleLabel.getStyleClass().add("stat-label");
        Label subtitleLabel = new Label(subtitle);
        subtitleLabel.getStyleClass().add("stat-subtitle");

        card.getChildren().addAll(valueLabel, titleLabel, subtitleLabel);
        return card;
    }
}
