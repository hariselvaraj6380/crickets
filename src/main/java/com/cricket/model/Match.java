package com.cricket.model;

public class Match {
    private int id;
    private String team1Name;
    private String team2Name;
    private int totalOvers;
    private MatchStatus status;

    private Innings firstInnings;
    private Innings secondInnings;

    private int targetRuns;
    private String winnerName;
    private String resultSummary;

    public Match(String team1Name, String team2Name, int totalOvers) {
        this.team1Name = team1Name;
        this.team2Name = team2Name;
        this.totalOvers = totalOvers;
        this.status = MatchStatus.FIRST_INNINGS;
        this.targetRuns = 0;
        this.winnerName = "";
        this.resultSummary = "";

        this.firstInnings = new Innings(0, 1, team1Name, team2Name, totalOvers);
        this.secondInnings = new Innings(0, 2, team2Name, team1Name, totalOvers);
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
        if (firstInnings != null) firstInnings.setMatchId(id);
        if (secondInnings != null) secondInnings.setMatchId(id);
    }

    public String getTeam1Name() {
        return team1Name;
    }

    public String getTeam2Name() {
        return team2Name;
    }

    public int getTotalOvers() {
        return totalOvers;
    }

    public MatchStatus getStatus() {
        return status;
    }

    public void setStatus(MatchStatus status) {
        this.status = status;
    }

    public Innings getFirstInnings() {
        return firstInnings;
    }

    public Innings getSecondInnings() {
        return secondInnings;
    }

    public Innings getCurrentInnings() {
        if (status == MatchStatus.SECOND_INNINGS) {
            return secondInnings;
        }
        return firstInnings;
    }

    public int getTargetRuns() {
        return targetRuns;
    }

    public void setTargetRuns(int targetRuns) {
        this.targetRuns = targetRuns;
    }

    public String getWinnerName() {
        return winnerName;
    }

    public String getResultSummary() {
        return resultSummary;
    }

    /**
     * Checks if 1st innings is completed and sets target for 2nd innings = 1st Innings Runs + 1.
     */
    public void updateMatchState() {
        if (status == MatchStatus.FIRST_INNINGS) {
            if (firstInnings.isCompleted()) {
                this.targetRuns = firstInnings.getTotalRuns() + 1;
                this.secondInnings.setTargetRuns(this.targetRuns);
                this.status = MatchStatus.SECOND_INNINGS;
            }
        } else if (status == MatchStatus.SECOND_INNINGS) {
            if (secondInnings.isCompleted() || secondInnings.getTotalRuns() >= targetRuns) {
                this.status = MatchStatus.COMPLETED;
                determineWinner();
            }
        }
    }

    private void determineWinner() {
        int t1Runs = firstInnings.getTotalRuns();
        int t2Runs = secondInnings.getTotalRuns();

        if (t2Runs >= targetRuns) {
            winnerName = team2Name;
            int wktsLeft = 10 - secondInnings.getTotalWickets();
            int ballsLeft = (totalOvers * 6) - secondInnings.getTotalLegalBalls();
            resultSummary = team2Name + " won by " + wktsLeft + " wickets (" + ballsLeft + " balls remaining)";
        } else if (t2Runs < t1Runs && secondInnings.isCompleted()) {
            winnerName = team1Name;
            int margin = t1Runs - t2Runs;
            resultSummary = team1Name + " won by " + margin + " runs";
        } else if (t2Runs == t1Runs && secondInnings.isCompleted()) {
            winnerName = "Tie";
            resultSummary = "Match Tied!";
        }
    }
}
