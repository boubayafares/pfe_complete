package com.foottech.admin.model;

public class Utilisateur {
    public long idUtilisateur;
    public String nom;
    public String prenom;
    public String email;
    public String telephone;
    public String role;
    public String dateCreation;
    public boolean actif;

    public String nomComplet() {
        return prenom + " " + nom;
    }
}
