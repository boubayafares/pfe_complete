package com.foottech.admin;

import com.foottech.admin.controller.LoginController;
import com.foottech.admin.controller.MainController;
import com.foottech.admin.service.ServiceLocator;
import com.foottech.admin.util.SceneManager;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.stage.Stage;

/** FootTech Admin Console - JavaFX desktop client for the Django admin backend. */
public class App extends Application {

    @Override
    public void start(Stage primaryStage) {
        SceneManager.init(primaryStage);
        primaryStage.setMinWidth(1000);
        primaryStage.setMinHeight(650);

        ServiceLocator services = ServiceLocator.getInstance();

        if (services.authService.hasSession()) {
            // Validate the persisted session in the background before entering the app.
            SceneManager.show("/fxml/Splash.fxml", "FootTech Admin - Chargement...", 1100, 700);
            new Thread(() -> {
                try {
                    services.currentAdmin = services.authService.me();
                    Platform.runLater(this::openMainShell);
                } catch (Exception e) {
                    services.authService.logout();
                    Platform.runLater(this::openLogin);
                }
            }, "session-check").start();
        } else {
            openLogin();
        }
    }

    private void openLogin() {
        LoginController controller = SceneManager.show(
                "/fxml/Login.fxml", "FootTech Admin - Connexion", 480, 560);
        controller.setOnLoginSuccess(this::openMainShell);
    }

    private void openMainShell() {
        MainController controller = SceneManager.show(
                "/fxml/Main.fxml", "FootTech Admin Console", 1200, 760);
        controller.init();
    }

    public static void main(String[] args) {
        launch(args);
    }
}
