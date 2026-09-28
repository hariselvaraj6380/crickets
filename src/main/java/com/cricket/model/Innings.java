package com.cricket.model;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Innings {
    private int id;
    private int matchId;
    private int inningsNumber; // 1 or 2
    private String battingTeam;
    private String bowlingTeam;
    private int maxOvers;

    private int totalRuns;
    private int totalWickets;
    private int totalLegalBalls;
    private int targetRuns; // 0 for 1st innings, set for 2nd innings
    private boolean isCompleted;

    private final List<Ball> recordedBalls;
    private final Map<String, Player> playersMap; // Player name -> Player
    private Player currentStriker;
    private Player currentNonStriker;
    private Player currentBowler;
    private final List<String> battingLineup;
    private int nextBattingIndex;

    public Innings(int matchId, int inningsNumber, String battingTeam, String bowlingTeam, int maxOvers) {
        this.matchId = matchId;
        this.inningsNumber = inningsNumber;
        this.battingTeam = battingTeam;
        this.bowlingTeam = bowlingTeam;
        this.maxOvers = maxOvers;
        this.totalRuns = 0;
        this.totalWickets = 0;
        this.totalLegalBalls = 0;
        this.targetRuns = 0;
        this.isCompleted = false;
        this.recordedBalls = new ArrayList<>();
        this.playersMap = new HashMap<>();
        this.battingLineup = new ArrayList<>();
        this.nextBattingIndex = 0;
    }

    public void setupPlayers(List<String> battingPlayers, List<String> bowlingPlayers) {
        for (String p : battingPlayers) {
            Player player = new Player(p, battingTeam);
            playersMap.put(p, player);
            battingLineup.add(p);
        }
        for (String p : bowlingPlayers) {
            Player player = new Player(p, bowlingTeam);
            playersMap.put(p, player);
        }

        if (battingLineup.size() >= 2) {
            currentStriker = playersMap.get(battingLineup.get(0));
            currentNonStriker = playersMap.get(battingLineup.get(1));
            nextBattingIndex = 2;
        }
        if (!bowlingPlayers.isEmpty()) {
            currentBowler = playersMap.get(bowlingPlayers.get(0));
        }
    }

    /**
     * Single entry point to record a delivery, update score/wickets/overs/player stats and rotate strike.
     */
    public synchronized void recordBall(Ball ball) {
        if (isCompleted) {
            return;
        }

        // 1. Calculate total runs on delivery
        int ballTotalRuns = ball.getTotalRuns();
        this.totalRuns += ballTotalRuns;

        boolean isLegal = ball.isLegalBall();
        if (isLegal) {
            this.totalLegalBalls++;
            ball.setLegalBallNumber(this.totalLegalBalls);
        } else {
            ball.setLegalBallNumber(this.totalLegalBalls);
        }

        // 2. Update player stats
        Player striker = getOrCreatePlayer(ball.getBatsmanName(), battingTeam);
        Player bowler = getOrCreatePlayer(ball.getBowlerName(), bowlingTeam);
        this.currentStriker = striker;
        this.currentBowler = bowler;

        // Batting stats update
        boolean countsAsBallFaced = (ball.getExtraType() != ExtraType.WIDE);
        striker.recordBatting(ball.getRunsOffBat(), countsAsBallFaced);

        // Bowling stats update (Wide/No-Ball runs count against bowler, Bye/Leg-Bye do not)
        int bowlingRuns = ball.getRunsOffBat();
        if (ball.getExtraType() == ExtraType.WIDE || ball.getExtraType() == ExtraType.NO_BALL) {
            bowlingRuns += 1 + ball.getExtraRuns();
        }
        boolean isWicketForBowler = ball.getWicketInfo().isWicket() && ball.getWicketInfo().getType() != WicketType.RUN_OUT;
        bowler.recordBowling(bowlingRuns, isLegal, isWicketForBowler);

        // 3. Handle Wicket
        if (ball.getWicketInfo().isWicket()) {
            this.totalWickets++;
            String dismissedName = ball.getWicketInfo().getDismissedPlayer();
            if (dismissedName == null || dismissedName.isEmpty()) {
                dismissedName = striker.getName();
            }
            Player dismissedPlayer = getOrCreatePlayer(dismissedName, battingTeam);
            dismissedPlayer.setOut(true, ball.getWicketInfo().getType().getDisplayName());

            // Bring next batsman in if available
            if (totalWickets < 10 && nextBattingIndex < battingLineup.size()) {
                Player newBatter = playersMap.get(battingLineup.get(nextBattingIndex++));
                if (dismissedPlayer.getName().equals(striker.getName())) {
                    currentStriker = newBatter;
                } else {
                    currentNonStriker = newBatter;
                }
            }
        }

        recordedBalls.add(ball);

        // 4. Strike Rotation
        int physicalRunsForStrike = ball.getRunsOffBat();
        if (ball.getExtraType() == ExtraType.BYE || ball.getExtraType() == ExtraType.LEG_BYE) {
            physicalRunsForStrike = ball.getExtraRuns();
        }

        // Swap strike on odd physical runs scored
        if (physicalRunsForStrike % 2 != 0) {
            swapStrike();
        }

        // End of over check: 6 legal balls in over
        if (isLegal && totalLegalBalls > 0 && totalLegalBalls % 6 == 0) {
            swapStrike(); // End of over strike rotation
        }

        // 5. Completion Check
        if (totalWickets >= 10 || totalLegalBalls >= maxOvers * 6) {
            isCompleted = true;
        } else if (targetRuns > 0 && totalRuns >= targetRuns) {
            isCompleted = true;
        }
    }

    public void swapStrike() {
        Player temp = currentStriker;
        currentStriker = currentNonStriker;
        currentNonStriker = temp;
    }

    public Player getOrCreatePlayer(String name, String team) {
        return playersMap.computeIfAbsent(name, k -> new Player(k, team));
    }

    // Getters and helper methods
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getMatchId() {
        return matchId;
    }

    public void setMatchId(int matchId) {
        this.matchId = matchId;
    }

    public int getInningsNumber() {
        return inningsNumber;
    }

    public String getBattingTeam() {
        return battingTeam;
    }

    public String getBowlingTeam() {
        return bowlingTeam;
    }

    public int getMaxOvers() {
        return maxOvers;
    }

    public int getTotalRuns() {
        return totalRuns;
    }

    public int getTotalWickets() {
        return totalWickets;
    }

    public int getTotalLegalBalls() {
        return totalLegalBalls;
    }

    public int getTargetRuns() {
        return targetRuns;
    }

    public void setTargetRuns(int targetRuns) {
        this.targetRuns = targetRuns;
    }

    public boolean isCompleted() {
        return isCompleted;
    }

    public void setCompleted(boolean completed) {
        isCompleted = completed;
    }

    public List<Ball> getRecordedBalls() {
        return recordedBalls;
    }

    public Player getCurrentStriker() {
        return currentStriker;
    }

    public void setCurrentStriker(Player currentStriker) {
        this.currentStriker = currentStriker;
    }

    public Player getCurrentNonStriker() {
        return currentNonStriker;
    }

    public void setCurrentNonStriker(Player currentNonStriker) {
        this.currentNonStriker = currentNonStriker;
    }

    public Player getCurrentBowler() {
        return currentBowler;
    }

    public void setCurrentBowler(Player currentBowler) {
        this.currentBowler = currentBowler;
    }

    public Map<String, Player> getPlayersMap() {
        return playersMap;
    }

    public String getOversFormatted() {
        int overs = totalLegalBalls / 6;
        int balls = totalLegalBalls % 6;
        return overs + "." + balls;
    }

    public double getOversAsDouble() {
        int overs = totalLegalBalls / 6;
        int balls = totalLegalBalls % 6;
        return overs + (balls / 6.0);
    }

    public double getCurrentRunRate() {
        double overs = getOversAsDouble();
        if (overs <= 0) return 0.0;
        return totalRuns / overs;
    }

    public double getRequiredRunRate() {
        if (targetRuns <= 0 || inningsNumber != 2) return 0.0;
        int runsNeeded = targetRuns - totalRuns;
        if (runsNeeded <= 0) return 0.0;

        int remainingBalls = (maxOvers * 6) - totalLegalBalls;
        if (remainingBalls <= 0) return 99.9;

        double remainingOvers = remainingBalls / 6.0;
        return runsNeeded / remainingOvers;
    }

    public List<Ball> getCurrentOverBalls() {
        if (recordedBalls.isEmpty()) return new ArrayList<>();
        int currentOver = (totalLegalBalls == 0) ? 0 : (totalLegalBalls % 6 == 0 && recordedBalls.get(recordedBalls.size() - 1).isLegalBall() ? (totalLegalBalls / 6) - 1 : totalLegalBalls / 6);
        List<Ball> overBalls = new ArrayList<>();
        for (int i = recordedBalls.size() - 1; i >= 0; i--) {
            Ball b = recordedBalls.get(i);
            if (b.getOverNumber() == currentOver) {
                overBalls.add(0, b);
            } else if (b.getOverNumber() < currentOver) {
                break;
            }
        }
        return overBalls;
    }
}
