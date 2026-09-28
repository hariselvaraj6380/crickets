package com.cricket.model;

public class WicketInfo {
    private final boolean isWicket;
    private final WicketType type;
    private final String dismissedPlayer;

    public WicketInfo(boolean isWicket, WicketType type, String dismissedPlayer) {
        this.isWicket = isWicket;
        this.type = type != null ? type : WicketType.NONE;
        this.dismissedPlayer = dismissedPlayer;
    }

    public static WicketInfo noWicket() {
        return new WicketInfo(false, WicketType.NONE, null);
    }

    public static WicketInfo wicket(WicketType type, String dismissedPlayer) {
        return new WicketInfo(true, type, dismissedPlayer);
    }

    public boolean isWicket() {
        return isWicket;
    }

    public WicketType getType() {
        return type;
    }

    public String getDismissedPlayer() {
        return dismissedPlayer;
    }

    @Override
    public String toString() {
        if (!isWicket) return "No Wicket";
        return type.getDisplayName() + (dismissedPlayer != null ? " (" + dismissedPlayer + ")" : "");
    }
}
