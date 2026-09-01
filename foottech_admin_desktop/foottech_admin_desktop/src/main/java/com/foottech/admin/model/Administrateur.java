package com.foottech.admin.model;

public class Administrateur {
    public long id;
    public String nom;
    public String prenom;
    public String email;
    public String role;
    public boolean isActive;
    public String dateCreation;

    public String nomComplet() {
        return prenom + " " + nom;
    }
}
