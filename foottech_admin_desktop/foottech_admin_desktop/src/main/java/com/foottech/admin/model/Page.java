package com.foottech.admin.model;

import java.util.List;

/** Mirrors DRF's default PageNumberPagination envelope. */
public class Page<T> {
    public int count;
    public String next;
    public String previous;
    public List<T> results;
}
