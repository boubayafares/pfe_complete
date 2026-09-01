package com.foottech.admin.controller;

import com.foottech.admin.network.ApiException;
import com.foottech.admin.service.ServiceLocator;
import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.PasswordField;
import javafx.scene.control.ProgressIndicator;
import javafx.scene.control.TextField;

public class LoginController {

    @FXML private TextField emailField;
    @FXML private PasswordField passwordField;
    @FXML private Label errorLabel;
    @FXML private ProgressIndicator loadingIndicator;
    @FXML private Button loginButton;

    private final ServiceLocator services = ServiceLocator.getInstance();
    private Runnable onLoginSuccess = () -> {};

    public void setOnLoginSuccess(Runnable callback) {
        this.onLoginSuccess = callback;
    }

    @FXML
    private void handleLogin() {
        String email = emailField.getText() == null ? "" : emailField.getText().trim();
        String password = passwordField.getText() == null ? "" : passwordField.getText();

        if (email.isEmpty() || password.isEmpty()) {
            showError("Veuillez renseigner l'email et le mot de passe.");
            return;
        }

        setLoading(true);
        new Thread(() -> {
            try {
                services.currentAdmin = services.authService.login(email, password);
                Platform.runLater(() -> {
                    setLoading(false);
                    onLoginSuccess.run();
                });
            } catch (ApiException e) {
                Platform.runLater(() -> {
                    setLoading(false);
                    showError(e.isUnauthorized() ? "Email ou mot de passe incorrect." : e.getMessage());
                });
            } catch (Exception e) {
                Platform.runLater(() -> {
                    setLoading(false);
                    showError("Erreur inattendue : " + e.getMessage());
                });
            }
        }, "login-request").start();
    }

    private void showError(String message) {
        errorLabel.setText(message);
        errorLabel.setVisible(true);
        errorLabel.setManaged(true);
    }

    private void setLoading(boolean loading) {
        loadingIndicator.setVisible(loading);
        loadingIndicator.setManaged(loading);
        loginButton.setDisable(loading);
        emailField.setDisable(loading);
        passwordField.setDisable(loading);
        if (!loading) return;
        errorLabel.setVisible(false);
        errorLabel.setManaged(false);
    }
}
