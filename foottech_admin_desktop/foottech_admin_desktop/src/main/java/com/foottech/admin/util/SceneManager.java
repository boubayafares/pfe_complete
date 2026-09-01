package com.foottech.admin.util;

import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

import java.io.IOException;
import java.util.Objects;

/** Loads FXML views and swaps them onto the single primary {@link Stage}. */
public final class SceneManager {
    private static Stage primaryStage;

    private SceneManager() {}

    public static void init(Stage stage) {
        primaryStage = stage;
    }

    public static <T> T show(String fxmlPath, String title, double width, double height) {
        try {
            FXMLLoader loader = new FXMLLoader(Objects.requireNonNull(
                    SceneManager.class.getResource(fxmlPath), "FXML introuvable: " + fxmlPath));
            Parent root = loader.load();
            Scene scene = new Scene(root, width, height);
            scene.getStylesheets().add(Objects.requireNonNull(
                    SceneManager.class.getResource("/css/style.css")).toExternalForm());
            primaryStage.setTitle(title);
            primaryStage.setScene(scene);
            primaryStage.show();
            return loader.getController();
        } catch (IOException e) {
            throw new RuntimeException("Impossible de charger " + fxmlPath, e);
        }
    }

    public static Stage stage() {
        return primaryStage;
    }
}
