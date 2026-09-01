package com.foottech.admin;

/**
 * Separate entry point (not extending javafx.application.Application) so the
 * shaded fat-jar can be run with a plain `java -jar ...` without requiring
 * the JavaFX runtime on the module path.
 */
public final class Launcher {
    private Launcher() {}

    public static void main(String[] args) {
        App.main(args);
    }
}
