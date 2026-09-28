package com.cricket.model;

public enum WicketType {
    NONE("Not Out"),
    BOWLED("Bowled"),
    CAUGHT("Caught"),
    LBW("LBW"),
    RUN_OUT("Run Out"),
    STUMPED("Stumped"),
    HIT_WICKET("Hit Wicket");

    private final String displayName;

    WicketType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    public boolean isWicket() {
        return this != NONE;
    }
}
