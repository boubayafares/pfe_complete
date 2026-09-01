package com.foottech.admin.controller;

import com.foottech.admin.model.AuditLog;
import com.foottech.admin.service.ServiceLocator;
import com.foottech.admin.util.AlertUtil;
import javafx.application.Platform;
import javafx.beans.property.SimpleStringProperty;
import javafx.collections.FXCollections;
import javafx.fxml.FXML;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;

public class AuditLogController {

    @FXML private TableView<AuditLog> logsTable;
    @FXML private TableColumn<AuditLog, String> colDate;
    @FXML private TableColumn<AuditLog, String> colAdmin;
    @FXML private TableColumn<AuditLog, String> colAction;
    @FXML private TableColumn<AuditLog, String> colCible;
    @FXML private TableColumn<AuditLog, String> colDetails;

    private final ServiceLocator services = ServiceLocator.getInstance();

    @FXML
    private void initialize() {
        colDate.setCellValueFactory(data -> new SimpleStringProperty(formatDate(data.getValue().dateAction)));
        colAdmin.setCellValueFactory(data -> new SimpleStringProperty(
                data.getValue().administrateurNom != null ? data.getValue().administrateurNom : "-"));
        colAction.setCellValueFactory(data -> new SimpleStringProperty(actionLabel(data.getValue().action)));
        colCible.setCellValueFactory(data -> {
            AuditLog log = data.getValue();
            String cible = log.cibleType + (log.cibleId != null ? " #" + log.cibleId : "");
            return new SimpleStringProperty(cible);
        });
        colDetails.setCellValueFactory(data -> new SimpleStringProperty(
                data.getValue().details != null ? data.getValue().details.toString() : ""));

        load();
    }

    private void load() {
        new Thread(() -> {
            try {
                var logs = services.auditLogService.list();
                Platform.runLater(() -> logsTable.setItems(FXCollections.observableArrayList(logs)));
            } catch (Exception e) {
                Platform.runLater(() -> AlertUtil.error("Impossible de charger le journal d'audit : " + e.getMessage()));
            }
        }, "auditlog-load").start();
    }

    private String actionLabel(String action) {
        if (action == null) return "-";
        return switch (action) {
            case "SUSPEND_TEAM" -> "Suspension d'équipe";
            case "ACTIVATE_TEAM" -> "Réactivation d'équipe";
            case "SUSPEND_USER" -> "Suspension d'utilisateur";
            case "ACTIVATE_USER" -> "Réactivation d'utilisateur";
            case "BROADCAST_NOTIFICATION" -> "Notification diffusée";
            case "CREATE_ADMIN" -> "Création d'administrateur";
            default -> action;
        };
    }

    private String formatDate(String iso) {
        if (iso == null) return "-";
        // Keep it simple/robust: show the raw ISO date-time truncated to minutes.
        return iso.length() >= 16 ? iso.substring(0, 16).replace("T", " ") : iso;
    }
}
