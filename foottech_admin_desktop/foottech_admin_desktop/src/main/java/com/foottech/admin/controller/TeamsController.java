package com.foottech.admin.controller;

import com.foottech.admin.model.Equipe;
import com.foottech.admin.service.ServiceLocator;
import com.foottech.admin.util.AlertUtil;
import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.fxml.FXML;
import javafx.scene.control.*;

import java.util.List;

public class TeamsController {

    @FXML private TextField searchField;
    @FXML private ChoiceBox<String> statusFilter;
    @FXML private TableView<Equipe> teamsTable;
    @FXML private TableColumn<Equipe, String> colNom;
    @FXML private TableColumn<Equipe, String> colCategorie;
    @FXML private TableColumn<Equipe, String> colSaison;
    @FXML private TableColumn<Equipe, String> colCoach;
    @FXML private TableColumn<Equipe, Number> colJoueurs;
    @FXML private TableColumn<Equipe, String> colStatut;
    @FXML private TableColumn<Equipe, Void> colActions;

    private final ServiceLocator services = ServiceLocator.getInstance();

    @FXML
    private void initialize() {
        statusFilter.setItems(FXCollections.observableArrayList("Toutes", "Actives", "Suspendues"));
        statusFilter.setValue("Toutes");

        colNom.setCellValueFactory(data -> new javafx.beans.property.SimpleStringProperty(data.getValue().nomEquipe));
        colCategorie.setCellValueFactory(data -> new javafx.beans.property.SimpleStringProperty(data.getValue().categorie));
        colSaison.setCellValueFactory(data -> new javafx.beans.property.SimpleStringProperty(data.getValue().saison));
        colCoach.setCellValueFactory(data -> {
            Equipe e = data.getValue();
            String label = (e.coach != null) ? e.coach.nomComplet() : "-";
            return new javafx.beans.property.SimpleStringProperty(label);
        });
        colJoueurs.setCellValueFactory(data -> new javafx.beans.property.SimpleIntegerProperty(data.getValue().nombreJoueurs));
        colStatut.setCellValueFactory(data ->
                new javafx.beans.property.SimpleStringProperty(data.getValue().actif ? "Active" : "Suspendue"));
        colActions.setCellFactory(col -> new SuspendActivateCell());

        applyFilters();
    }

    @FXML
    private void applyFilters() {
        String search = searchField.getText();
        Boolean actif = switch (statusFilter.getValue()) {
            case "Actives" -> Boolean.TRUE;
            case "Suspendues" -> Boolean.FALSE;
            default -> null;
        };

        new Thread(() -> {
            try {
                List<Equipe> teams = services.teamsService.list(search, actif);
                Platform.runLater(() -> teamsTable.setItems(FXCollections.observableArrayList(teams)));
            } catch (Exception e) {
                Platform.runLater(() -> AlertUtil.error("Impossible de charger les équipes : " + e.getMessage()));
            }
        }, "teams-load").start();
    }

    private class SuspendActivateCell extends TableCell<Equipe, Void> {
        private final Button button = new Button();

        SuspendActivateCell() {
            button.setOnAction(e -> {
                Equipe team = getTableView().getItems().get(getIndex());
                toggleTeam(team);
            });
        }

        @Override
        protected void updateItem(Void item, boolean empty) {
            super.updateItem(item, empty);
            if (empty) {
                setGraphic(null);
                return;
            }
            Equipe team = getTableView().getItems().get(getIndex());
            button.setText(team.actif ? "Suspendre" : "Réactiver");
            button.getStyleClass().setAll("table-action-button", team.actif ? "danger-button" : "success-button");
            setGraphic(button);
        }
    }

    private void toggleTeam(Equipe team) {
        boolean suspending = team.actif;
        String title = suspending ? "Suspendre l'équipe" : "Réactiver l'équipe";
        boolean confirmed = AlertUtil.confirm(title, "Confirmez-vous cette action pour \"" + team.nomEquipe + "\" ?");
        if (!confirmed) return;

        new Thread(() -> {
            try {
                if (suspending) {
                    services.teamsService.suspend(team.idEquipe, "Suspendu depuis la console admin");
                } else {
                    services.teamsService.activate(team.idEquipe, null);
                }
                Platform.runLater(this::applyFilters);
            } catch (Exception e) {
                Platform.runLater(() -> AlertUtil.error("Action impossible : " + e.getMessage()));
            }
        }, "team-toggle").start();
    }
}
