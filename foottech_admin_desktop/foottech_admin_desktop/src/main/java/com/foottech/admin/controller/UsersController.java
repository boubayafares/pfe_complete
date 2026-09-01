package com.foottech.admin.controller;

import com.foottech.admin.model.Utilisateur;
import com.foottech.admin.service.ServiceLocator;
import com.foottech.admin.util.AlertUtil;
import javafx.application.Platform;
import javafx.beans.property.SimpleStringProperty;
import javafx.collections.FXCollections;
import javafx.fxml.FXML;
import javafx.scene.control.*;

import java.util.List;

public class UsersController {

    @FXML private TextField searchField;
    @FXML private ChoiceBox<String> roleFilter;
    @FXML private ChoiceBox<String> statusFilter;
    @FXML private TableView<Utilisateur> usersTable;
    @FXML private TableColumn<Utilisateur, String> colNom;
    @FXML private TableColumn<Utilisateur, String> colEmail;
    @FXML private TableColumn<Utilisateur, String> colTelephone;
    @FXML private TableColumn<Utilisateur, String> colRole;
    @FXML private TableColumn<Utilisateur, String> colStatut;
    @FXML private TableColumn<Utilisateur, Void> colActions;

    private final ServiceLocator services = ServiceLocator.getInstance();

    @FXML
    private void initialize() {
        roleFilter.setItems(FXCollections.observableArrayList("TOUS", "COACH", "ADJOINT", "JOUEUR"));
        roleFilter.setValue("TOUS");
        statusFilter.setItems(FXCollections.observableArrayList("Tous", "Actifs", "Suspendus"));
        statusFilter.setValue("Tous");

        colNom.setCellValueFactory(data -> new SimpleStringProperty(data.getValue().nomComplet()));
        colEmail.setCellValueFactory(data -> new SimpleStringProperty(data.getValue().email));
        colTelephone.setCellValueFactory(data -> new SimpleStringProperty(data.getValue().telephone));
        colRole.setCellValueFactory(data -> new SimpleStringProperty(data.getValue().role));
        colStatut.setCellValueFactory(data -> new SimpleStringProperty(data.getValue().actif ? "Actif" : "Suspendu"));
        colActions.setCellFactory(col -> new SuspendActivateCell());

        applyFilters();
    }

    @FXML
    private void applyFilters() {
        String search = searchField.getText();
        String role = roleFilter.getValue();
        Boolean actif = switch (statusFilter.getValue()) {
            case "Actifs" -> Boolean.TRUE;
            case "Suspendus" -> Boolean.FALSE;
            default -> null;
        };

        new Thread(() -> {
            try {
                List<Utilisateur> users = services.usersService.list(search, role, actif);
                Platform.runLater(() -> usersTable.setItems(FXCollections.observableArrayList(users)));
            } catch (Exception e) {
                Platform.runLater(() -> AlertUtil.error("Impossible de charger les utilisateurs : " + e.getMessage()));
            }
        }, "users-load").start();
    }

    private class SuspendActivateCell extends TableCell<Utilisateur, Void> {
        private final Button button = new Button();

        SuspendActivateCell() {
            button.setOnAction(e -> {
                Utilisateur user = getTableView().getItems().get(getIndex());
                toggleUser(user);
            });
        }

        @Override
        protected void updateItem(Void item, boolean empty) {
            super.updateItem(item, empty);
            if (empty) {
                setGraphic(null);
                return;
            }
            Utilisateur user = getTableView().getItems().get(getIndex());
            button.setText(user.actif ? "Suspendre" : "Réactiver");
            button.getStyleClass().setAll("table-action-button", user.actif ? "danger-button" : "success-button");
            setGraphic(button);
        }
    }

    private void toggleUser(Utilisateur user) {
        boolean suspending = user.actif;
        String title = suspending ? "Suspendre le compte" : "Réactiver le compte";
        boolean confirmed = AlertUtil.confirm(title, "Confirmez-vous cette action pour \"" + user.nomComplet() + "\" ?");
        if (!confirmed) return;

        new Thread(() -> {
            try {
                if (suspending) {
                    services.usersService.suspend(user.idUtilisateur, "Suspendu depuis la console admin");
                } else {
                    services.usersService.activate(user.idUtilisateur, null);
                }
                Platform.runLater(this::applyFilters);
            } catch (Exception e) {
                Platform.runLater(() -> AlertUtil.error("Action impossible : " + e.getMessage()));
            }
        }, "user-toggle").start();
    }
}
