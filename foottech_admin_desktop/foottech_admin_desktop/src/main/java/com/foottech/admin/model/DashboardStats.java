package com.foottech.admin.model;

import java.util.List;

public class DashboardStats {
    public Equipes equipes;
    public Utilisateurs utilisateurs;
    public Joueurs joueurs;
    public Activite activite;

    public static class Equipes {
        public int total;
        public int actives;
        public int suspendues;
    }

    public static class Utilisateurs {
        public int total;
        public List<RoleCount> parRole;
        public int actifs;
        public int suspendus;
    }

    public static class RoleCount {
        public String role;
        public int total;
    }

    public static class Joueurs {
        public int total;
        public int comptesActives;
        public int enAttenteActivation;
    }

    public static class Activite {
        public int matchsCeMois;
        public int entrainementsAVenir;
    }
}
