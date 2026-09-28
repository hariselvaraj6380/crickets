package com.cricket.model;

public enum MatchStatus {
    NOT_STARTED("Not Started"),
    FIRST_INNINGS("1st Innings"),
    INNINGS_BREAK("Innings Break"),
    SECOND_INNINGS("2nd Innings"),
    COMPLETED("Match Completed");

    private final String displayName;

    MatchStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
