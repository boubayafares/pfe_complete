package com.foottech.admin.model;

import com.fasterxml.jackson.databind.JsonNode;

public class AuditLog {
    public long id;
    public String administrateurNom;
    public String action;
    public String cibleType;
    public Long cibleId;
    public JsonNode details;
    public String dateAction;
}
