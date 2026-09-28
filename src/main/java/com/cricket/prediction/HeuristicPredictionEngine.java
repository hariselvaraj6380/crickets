package com.cricket.prediction;

import com.cricket.model.Innings;
import com.cricket.model.Match;
import com.cricket.model.MatchStatus;
import com.cricket.model.PredictionResult;

public class HeuristicPredictionEngine implements PredictionEngine {

    @Override
    public PredictionResult predict(Match match) {
        if (match == null) {
            return new PredictionResult(0, 50.0, "No match active");
        }

        MatchStatus status = match.getStatus();
        if (status == MatchStatus.SECOND_INNINGS) {
            return predictSecondInnings(match);
        } else {
            return predictFirstInnings(match);
        }
    }

    private PredictionResult predictFirstInnings(Match match) {
        Innings innings = match.getFirstInnings();
        int totalRuns = innings.getTotalRuns();
        int wickets = innings.getTotalWickets();
        int legalBalls = innings.getTotalLegalBalls();
        int maxOvers = innings.getMaxOvers();
        int maxBalls = maxOvers * 6;

        if (wickets >= 10 || legalBalls >= maxBalls) {
            return new PredictionResult(totalRuns, 50.0, "1st Innings completed. Total: " + totalRuns);
        }

        double oversCompleted = innings.getOversAsDouble();
        double currentRR = innings.getCurrentRunRate();

        // Baseline run rate for early overs
        double effectiveRR = (oversCompleted < 1.0) ? 7.5 : currentRR;

        // Wickets in hand dampener: (wicketsInHand / 10)^0.5
        int wicketsInHand = 10 - wickets;
        double wicketDampener = Math.sqrt(wicketsInHand / 10.0);

        // Death overs acceleration factor
        double accelerationFactor = 1.0;
        int remainingBalls = maxBalls - legalBalls;
        double remainingOvers = remainingBalls / 6.0;

        if (oversCompleted >= (maxOvers - 5)) { // Death overs (last 5 overs)
            if (wicketsInHand >= 5) {
                accelerationFactor = 1.25;
            } else if (wicketsInHand >= 3) {
                accelerationFactor = 1.10;
            } else {
                accelerationFactor = 0.90;
            }
        } else if (oversCompleted >= 6) { // Middle overs
            accelerationFactor = 1.05;
        }

        int projectedRemainingRuns = (int) Math.round(remainingOvers * effectiveRR * accelerationFactor * wicketDampener);
        int projectedScore = totalRuns + projectedRemainingRuns;

        // Win probability for 1st innings batting team based on projected score benchmark (160)
        double winProbBatting = 50.0 + (projectedScore - 160) * 0.45;
        winProbBatting = Math.max(10.0, Math.min(90.0, winProbBatting));

        String explanation = String.format("Projected %d (CRR %.1f, %d wkts in hand, Accel %.2fx)",
                projectedScore, currentRR, wicketsInHand, accelerationFactor);

        return new PredictionResult(projectedScore, winProbBatting, explanation);
    }

    private PredictionResult predictSecondInnings(Match match) {
        Innings innings = match.getSecondInnings();
        int target = match.getTargetRuns();
        int totalRuns = innings.getTotalRuns();
        int wickets = innings.getTotalWickets();
        int legalBalls = innings.getTotalLegalBalls();
        int maxOvers = innings.getMaxOvers();
        int totalBalls = maxOvers * 6;
        int remainingBalls = totalBalls - legalBalls;
        int runsNeeded = target - totalRuns;

        // Base cases
        if (runsNeeded <= 0) {
            return new PredictionResult(totalRuns, 100.0, match.getTeam2Name() + " achieved the target!");
        }
        if (wickets >= 10 || remainingBalls <= 0) {
            return new PredictionResult(totalRuns, 0.0, match.getTeam1Name() + " defended the target!");
        }

        double crr = innings.getCurrentRunRate();
        double rrr = innings.getRequiredRunRate();
        int wicketsInHand = 10 - wickets;

        // Logistic score z
        // z > 0 favors chasing team, z < 0 favors bowling team
        double rrrDiff = crr - rrr;
        double parWicketsLost = 10.0 * ((double) legalBalls / totalBalls);
        double wicketAdvantage = wicketsInHand - (10.0 - parWicketsLost);
        double ballFactor = (double) remainingBalls / 30.0;

        double z = (rrrDiff * 0.6) + (wicketAdvantage * 0.45) + (ballFactor * 0.1);

        // Logistic sigmoid function: 100 / (1 + e^-z)
        double winProbabilityBatting = 100.0 / (1.0 + Math.exp(-z));
        winProbabilityBatting = Math.max(1.0, Math.min(99.0, winProbabilityBatting));

        int projectedScore = totalRuns + (int) Math.round((remainingBalls / 6.0) * (crr > 0 ? crr : 7.0));

        String explanation = String.format("Needs %d off %d balls, RRR %.1f vs current RR %.1f, %d wkts in hand",
                runsNeeded, remainingBalls, rrr, crr, wicketsInHand);

        return new PredictionResult(projectedScore, winProbabilityBatting, explanation);
    }
}
