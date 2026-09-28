package com.cricket.simulator;

import com.cricket.model.*;
import com.cricket.service.MatchService;
import javafx.animation.KeyFrame;
import javafx.animation.Timeline;
import javafx.util.Duration;

import java.util.Arrays;
import java.util.List;
import java.util.Random;

public class MatchSimulator {

    private final MatchService matchService;
    private Timeline timeline;
    private final Random random;
    private double speedMultiplier = 1.0;

    private static final List<String> INDIA_PLAYERS = Arrays.asList(
            "Rohit Sharma", "Yashasvi Jaiswal", "Virat Kohli", "Suryakumar Yadav",
            "Rishabh Pant", "Hardik Pandya", "Axar Patel", "Ravindra Jadeja",
            "Kuldeep Yadav", "Jasprit Bumrah", "Mohammed Siraj"
    );

    private static final List<String> AUSTRALIA_PLAYERS = Arrays.asList(
            "Travis Head", "David Warner", "Mitchell Marsh", "Glenn Maxwell", "Marcus Stoinis",
            "Tim David", "Matthew Wade", "Pat Cummins", "Mitchell Starc", "Adam Zampa", "Josh Hazlewood"
    );

    private int currentBowlerIndex = 7; // Start with frontline bowler

    private java.util.concurrent.ScheduledExecutorService executorService;
    private java.util.concurrent.ScheduledFuture<?> scheduledFuture;
    private boolean isRunningState = false;

    public MatchSimulator(MatchService matchService) {
        this.matchService = matchService;
        this.random = new Random();
        initTimeline();
    }

    private void initTimeline() {
        try {
            if (timeline != null) {
                timeline.stop();
            }
            timeline = new Timeline(new KeyFrame(Duration.seconds(1.5 / speedMultiplier), e -> generateNextBall()));
            timeline.setCycleCount(Timeline.INDEFINITE);
        } catch (Throwable t) {
            // JavaFX Toolkit might not be initialized in headless REST server mode
            timeline = null;
        }
    }

    public synchronized void start() {
        if (matchService.getCurrentMatch() == null || matchService.getCurrentMatch().getStatus() == MatchStatus.COMPLETED) {
            resetNewMatch();
        }
        isRunningState = true;
        if (timeline != null) {
            try {
                timeline.play();
                return;
            } catch (Throwable ignored) {}
        }
        
        // Fallback for headless API execution
        stopScheduledExecutor();
        executorService = java.util.concurrent.Executors.newSingleThreadScheduledExecutor();
        long periodMs = (long) (1500 / speedMultiplier);
        scheduledFuture = executorService.scheduleAtFixedRate(this::generateNextBall, periodMs, periodMs, java.util.concurrent.TimeUnit.MILLISECONDS);
    }

    public synchronized void pause() {
        isRunningState = false;
        if (timeline != null) {
            try {
                timeline.pause();
            } catch (Throwable ignored) {}
        }
        stopScheduledExecutor();
    }

    public synchronized void stop() {
        isRunningState = false;
        if (timeline != null) {
            try {
                timeline.stop();
            } catch (Throwable ignored) {}
        }
        stopScheduledExecutor();
    }

    private void stopScheduledExecutor() {
        if (scheduledFuture != null) {
            scheduledFuture.cancel(true);
            scheduledFuture = null;
        }
        if (executorService != null) {
            executorService.shutdownNow();
            executorService = null;
        }
    }

    public boolean isRunning() {
        if (timeline != null) {
            try {
                return timeline.getStatus() == Timeline.Status.RUNNING;
            } catch (Throwable ignored) {}
        }
        return isRunningState;
    }

    public double getSpeedMultiplier() {
        return speedMultiplier;
    }

    public synchronized void setSpeedMultiplier(double multiplier) {
        this.speedMultiplier = Math.max(0.2, Math.min(10.0, multiplier));
        boolean running = isRunning();
        stop();
        initTimeline();
        if (running) {
            start();
        }
    }

    public void resetNewMatch() {
        stop();
        Match match = new Match("India", "Australia", 20);
        matchService.startNewMatch(match, INDIA_PLAYERS, AUSTRALIA_PLAYERS);
        currentBowlerIndex = 7;
    }

    private void generateNextBall() {
        Match match = matchService.getCurrentMatch();
        if (match == null || match.getStatus() == MatchStatus.COMPLETED) {
            stop();
            return;
        }

        Innings innings = match.getCurrentInnings();

        // Check if bowler needs rotation at start of new over
        if (innings.getTotalLegalBalls() > 0 && innings.getTotalLegalBalls() % 6 == 0 &&
                (innings.getRecordedBalls().isEmpty() || innings.getRecordedBalls().get(innings.getRecordedBalls().size() - 1).isLegalBall())) {

            List<String> bowlingTeamList = (innings.getInningsNumber() == 1) ? AUSTRALIA_PLAYERS : INDIA_PLAYERS;
            currentBowlerIndex = 5 + random.nextInt(bowlingTeamList.size() - 5);
            String nextBowler = bowlingTeamList.get(currentBowlerIndex);
            innings.setCurrentBowler(innings.getOrCreatePlayer(nextBowler, innings.getBowlingTeam()));
        }

        Player striker = innings.getCurrentStriker();
        Player nonStriker = innings.getCurrentNonStriker();
        Player bowler = innings.getCurrentBowler();

        if (striker == null || bowler == null || nonStriker == null) {
            stop();
            return;
        }

        int overNumber = (innings.getTotalLegalBalls() == 0) ? 0 :
                (innings.getTotalLegalBalls() % 6 == 0 ? innings.getTotalLegalBalls() / 6 : innings.getTotalLegalBalls() / 6);
        int ballInOver = (innings.getTotalLegalBalls() % 6) + 1;

        // Weighted outcome simulation
        double outcomeRoll = random.nextDouble() * 100.0;
        int runs = 0;
        ExtraType extraType = ExtraType.NONE;
        int extraRuns = 0;
        WicketType wicketType = WicketType.NONE;

        if (outcomeRoll < 32.0) {
            runs = 0; // Dot ball (32%)
        } else if (outcomeRoll < 62.0) {
            runs = 1; // Single (30%)
        } else if (outcomeRoll < 74.0) {
            runs = 2; // Double (12%)
        } else if (outcomeRoll < 77.0) {
            runs = 3; // Triple (3%)
        } else if (outcomeRoll < 87.0) {
            runs = 4; // Boundary 4 (10%)
        } else if (outcomeRoll < 93.0) {
            runs = 6; // Six (6%)
        } else if (outcomeRoll < 97.0) {
            // Wicket (4%)
            WicketType[] wickets = {WicketType.BOWLED, WicketType.CAUGHT, WicketType.LBW, WicketType.RUN_OUT, WicketType.STUMPED};
            wicketType = wickets[random.nextInt(wickets.length)];
        } else {
            // Extra: Wide or No Ball (3%)
            extraType = random.nextBoolean() ? ExtraType.WIDE : ExtraType.NO_BALL;
            extraRuns = random.nextDouble() < 0.2 ? 1 : 0; // Extra run occasionally
        }

        WicketInfo wicketInfo = (wicketType != WicketType.NONE) ?
                WicketInfo.wicket(wicketType, striker.getName()) : WicketInfo.noWicket();

        String commentary = buildSimulationCommentary(striker.getName(), bowler.getName(), runs, extraType, wicketType);

        Ball ball = new Ball(
                match.getId(),
                innings.getInningsNumber(),
                overNumber,
                ballInOver,
                bowler.getName(),
                striker.getName(),
                nonStriker.getName(),
                runs,
                extraType,
                extraRuns,
                wicketInfo,
                commentary
        );

        matchService.processBall(ball);
    }

    public synchronized void stepSingleBall() {
        generateNextBall();
    }

    public synchronized void injectCustomBall(int runs, String extraTypeStr, String wicketTypeStr) {
        Match match = matchService.getCurrentMatch();
        if (match == null || match.getStatus() == MatchStatus.COMPLETED) {
            return;
        }

        Innings innings = match.getCurrentInnings();
        Player striker = innings.getCurrentStriker();
        Player nonStriker = innings.getCurrentNonStriker();
        Player bowler = innings.getCurrentBowler();

        if (striker == null || bowler == null || nonStriker == null) {
            return;
        }

        int overNumber = innings.getTotalLegalBalls() / 6;
        int ballInOver = (innings.getTotalLegalBalls() % 6) + 1;

        ExtraType extraType = ExtraType.NONE;
        if ("WIDE".equalsIgnoreCase(extraTypeStr)) extraType = ExtraType.WIDE;
        else if ("NO_BALL".equalsIgnoreCase(extraTypeStr)) extraType = ExtraType.NO_BALL;
        else if ("BYE".equalsIgnoreCase(extraTypeStr)) extraType = ExtraType.BYE;
        else if ("LEG_BYE".equalsIgnoreCase(extraTypeStr)) extraType = ExtraType.LEG_BYE;

        WicketType wicketType = WicketType.NONE;
        if (wicketTypeStr != null && !wicketTypeStr.equalsIgnoreCase("NONE")) {
            try {
                wicketType = WicketType.valueOf(wicketTypeStr.toUpperCase());
            } catch (Exception e) {
                wicketType = WicketType.BOWLED;
            }
        }

        WicketInfo wicketInfo = (wicketType != WicketType.NONE) ?
                WicketInfo.wicket(wicketType, striker.getName()) : WicketInfo.noWicket();

        String commentary = buildSimulationCommentary(striker.getName(), bowler.getName(), runs, extraType, wicketType);

        Ball ball = new Ball(
                match.getId(),
                innings.getInningsNumber(),
                overNumber,
                ballInOver,
                bowler.getName(),
                striker.getName(),
                nonStriker.getName(),
                runs,
                extraType,
                extraType != ExtraType.NONE ? 1 : 0,
                wicketInfo,
                commentary
        );

        matchService.processBall(ball);
    }

    private String buildSimulationCommentary(String striker, String bowler, int runs, ExtraType extra, WicketType wicket) {
        if (wicket.isWicket()) {
            return "OUT! " + bowler + " strikes! " + striker + " is " + wicket.getDisplayName() + "!";
        }
        if (extra == ExtraType.WIDE) return "Wide ball! " + bowler + " strays down the leg side.";
        if (extra == ExtraType.NO_BALL) return "No Ball! " + bowler + " oversteps the line.";
        if (runs == 4) return "FOUR! Cracking shot by " + striker + " through cover off " + bowler + "!";
        if (runs == 6) return "SIX! Huge hit into the stands by " + striker + "!";
        if (runs == 0) return "Dot ball. Good tight line by " + bowler + " to " + striker + ".";
        return runs + " run" + (runs > 1 ? "s" : "") + " to " + striker + ".";
    }
}
