package com.cricket.model;

public enum ExtraType {
    NONE("None"),
    WIDE("Wide"),
    NO_BALL("No Ball"),
    BYE("Bye"),
    LEG_BYE("Leg Bye");

    private final String displayName;

    ExtraType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    public boolean isExtra() {
        return this != NONE;
    }

    public boolean countsAsLegalBall() {
        return this != WIDE && this != NO_BALL;
    }
}
