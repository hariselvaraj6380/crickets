package com.cricket.model;

import java.time.LocalDateTime;

public class Ball {
    private int id;
    private int matchId;
    private int inningsNumber;
    private int overNumber;         // 0-indexed (e.g. 0 for 1st over)
    private int ballInOver;         // 1-based delivery counter in current over
    private int legalBallNumber;    // Cumulative legal balls in innings
    private String bowlerName;
    private String batsmanName;     // Striker
    private String nonStrikerName;
    private int runsOffBat;
    private ExtraType extraType;
    private int extraRuns;
    private WicketInfo wicketInfo;
    private String commentary;
    private LocalDateTime recordedAt;

    public Ball(int matchId, int inningsNumber, int overNumber, int ballInOver,
                String bowlerName, String batsmanName, String nonStrikerName,
                int runsOffBat, ExtraType extraType, int extraRuns,
                WicketInfo wicketInfo, String commentary) {
        this.matchId = matchId;
        this.inningsNumber = inningsNumber;
        this.overNumber = overNumber;
        this.ballInOver = ballInOver;
        this.bowlerName = bowlerName;
        this.batsmanName = batsmanName;
        this.nonStrikerName = nonStrikerName;
        this.runsOffBat = runsOffBat;
        this.extraType = extraType != null ? extraType : ExtraType.NONE;
        this.extraRuns = extraRuns;
        this.wicketInfo = wicketInfo != null ? wicketInfo : WicketInfo.noWicket();
        this.commentary = commentary != null ? commentary : "";
        this.recordedAt = LocalDateTime.now();
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getMatchId() {
        return matchId;
    }

    public int getInningsNumber() {
        return inningsNumber;
    }

    public int getOverNumber() {
        return overNumber;
    }

    public int getBallInOver() {
        return ballInOver;
    }

    public int getLegalBallNumber() {
        return legalBallNumber;
    }

    public void setLegalBallNumber(int legalBallNumber) {
        this.legalBallNumber = legalBallNumber;
    }

    public String getBowlerName() {
        return bowlerName;
    }

    public String getBatsmanName() {
        return batsmanName;
    }

    public String getNonStrikerName() {
        return nonStrikerName;
    }

    public int getRunsOffBat() {
        return runsOffBat;
    }

    public ExtraType getExtraType() {
        return extraType;
    }

    public int getExtraRuns() {
        return extraRuns;
    }

    public WicketInfo getWicketInfo() {
        return wicketInfo;
    }

    public String getCommentary() {
        return commentary;
    }

    public LocalDateTime getRecordedAt() {
        return recordedAt;
    }

    public void setRecordedAt(LocalDateTime recordedAt) {
        this.recordedAt = recordedAt;
    }

    public int getTotalRuns() {
        int total = runsOffBat + extraRuns;
        if (extraType == ExtraType.WIDE || extraType == ExtraType.NO_BALL) {
            total += 1; // Standard 1 run penalty for wide / no-ball plus extra runs
        }
        return total;
    }

    public boolean isLegalBall() {
        return extraType.countsAsLegalBall();
    }

    public boolean isBoundary() {
        return runsOffBat == 4 || runsOffBat == 6;
    }

    public String getChipText() {
        if (wicketInfo.isWicket()) {
            return "W";
        }
        if (extraType == ExtraType.WIDE) {
            return (extraRuns > 0) ? (extraRuns + 1) + "Wd" : "Wd";
        }
        if (extraType == ExtraType.NO_BALL) {
            return (runsOffBat > 0) ? (runsOffBat + 1) + "Nb" : "Nb";
        }
        if (extraType == ExtraType.BYE) {
            return extraRuns + "B";
        }
        if (extraType == ExtraType.LEG_BYE) {
            return extraRuns + "Lb";
        }
        return String.valueOf(runsOffBat);
    }
}
