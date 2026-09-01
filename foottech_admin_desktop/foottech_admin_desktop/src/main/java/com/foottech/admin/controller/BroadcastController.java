package com.foottech.admin.controller;

import com.foottech.admin.service.ServiceLocator;
import com.foottech.admin.util.AlertUtil;
import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.ChoiceBox;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressIndicator;
import javafx.scene.control.TextArea;

public class BroadcastController {

    @FXML private ChoiceBox<String> targetRoleChoice;
    @FXML private TextArea messageArea;
    @FXML private Button sendButton;
    @FXML private ProgressIndicator loadingIndicator;
    @FXML private Label resultLabel;

    private final ServiceLocator services = ServiceLocator.getInstance();

    @FXML
    private void initialize() {
        targetRoleChoice.setItems(FXCollections.observableArrayList("TOUS", "COACH", "ADJOINT", "JOUEUR"));
        targetRoleChoice.setValue("TOUS");
    }

    @FXML
    private void handleSend() {
        String message = messageArea.getText() == null ? "" : messageArea.getText().trim();
        if (message.isEmpty()) {
            AlertUtil.error("Le message ne peut pas être vide.");
            return;
        }
        String role = targetRoleChoice.getValue();

        boolean confirmed = AlertUtil.confirm(
                "Confirmer la diffusion",
                "Envoyer ce message à : " + role + " ?\n\n\"" + message + "\""
        );
        if (!confirmed) return;

        setLoading(true);
        new Thread(() -> {
            try {
                int count = services.broadcastService.send(message, role);
                Platform.runLater(() -> {
                    setLoading(false);
                    resultLabel.setText("Notification envoyée à " + count + " destinataire(s).");
                    resultLabel.setVisible(true);
                    resultLabel.setManaged(true);
                    messageArea.clear();
                });
            } catch (Exception e) {
                Platform.runLater(() -> {
                    setLoading(false);
                    AlertUtil.error("Échec de l'envoi : " + e.getMessage());
                });
            }
        }, "broadcast-send").start();
    }

    private void setLoading(boolean loading) {
        loadingIndicator.setVisible(loading);
        loadingIndicator.setManaged(loading);
        sendButton.setDisable(loading);
        if (loading) {
            resultLabel.setVisible(false);
            resultLabel.setManaged(false);
        }
    }
}
