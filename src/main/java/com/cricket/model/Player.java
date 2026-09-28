package com.cricket.model;

public class Player {
    private int id;
    private String name;
    private String teamName;

    // Batting stats
    private int runsScored;
    private int ballsFaced;
    private int fours;
    private int sixes;
    private boolean isOut;
    private String dismissalInfo;

    // Bowling stats
    private int bowlingLegalBalls;
    private int bowlingRunsConceded;
    private int bowlingWickets;

    public Player(String name, String teamName) {
        this.name = name;
        this.teamName = teamName;
        this.runsScored = 0;
        this.ballsFaced = 0;
        this.fours = 0;
        this.sixes = 0;
        this.isOut = false;
        this.dismissalInfo = "";
        this.bowlingLegalBalls = 0;
        this.bowlingRunsConceded = 0;
        this.bowlingWickets = 0;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public String getTeamName() {
        return teamName;
    }

    // Batting getters & updates
    public int getRunsScored() {
        return runsScored;
    }

    public int getBallsFaced() {
        return ballsFaced;
    }

    public int getFours() {
        return fours;
    }

    public int getSixes() {
        return sixes;
    }

    public boolean isOut() {
        return isOut;
    }

    public String getDismissalInfo() {
        return dismissalInfo;
    }

    public void setOut(boolean out, String dismissalInfo) {
        isOut = out;
        this.dismissalInfo = dismissalInfo;
    }

    public double getStrikeRate() {
        if (ballsFaced == 0) return 0.0;
        return (runsScored * 100.0) / ballsFaced;
    }

    public void recordBatting(int runs, boolean countsAsBallFaced) {
        this.runsScored += runs;
        if (countsAsBallFaced) {
            this.ballsFaced++;
        }
        if (runs == 4) fours++;
        if (runs == 6) sixes++;
    }

    // Bowling getters & updates
    public int getBowlingLegalBalls() {
        return bowlingLegalBalls;
    }

    public int getBowlingRunsConceded() {
        return bowlingRunsConceded;
    }

    public int getBowlingWickets() {
        return bowlingWickets;
    }

    public String getBowlingOversString() {
        int fullOvers = bowlingLegalBalls / 6;
        int remainingBalls = bowlingLegalBalls % 6;
        return fullOvers + "." + remainingBalls;
    }

    public double getBowlingOversDouble() {
        int fullOvers = bowlingLegalBalls / 6;
        int remainingBalls = bowlingLegalBalls % 6;
        return fullOvers + (remainingBalls / 6.0);
    }

    public double getEconomyRate() {
        double overs = getBowlingOversDouble();
        if (overs == 0) return 0.0;
        return bowlingRunsConceded / overs;
    }

    public void recordBowling(int runs, boolean isLegalBall, boolean isWicket) {
        this.bowlingRunsConceded += runs;
        if (isLegalBall) {
            this.bowlingLegalBalls++;
        }
        if (isWicket) {
            this.bowlingWickets++;
        }
    }

    public String getBowlingFigures() {
        return bowlingWickets + "-" + bowlingRunsConceded + " (" + getBowlingOversString() + " ov)";
    }

    @Override
    public String toString() {
        return name + " (" + teamName + ")";
    }
}
