package com.cricket.model;

public class PredictionResult {
    private final int projectedScore;
    private final double winProbabilityBatting; // 0.0 to 100.0%
    private final String explanation;

    public PredictionResult(int projectedScore, double winProbabilityBatting, String explanation) {
        this.projectedScore = projectedScore;
        this.winProbabilityBatting = Math.max(0.0, Math.min(100.0, winProbabilityBatting));
        this.explanation = explanation != null ? explanation : "";
    }

    public int getProjectedScore() {
        return projectedScore;
    }

    public double getWinProbabilityBatting() {
        return winProbabilityBatting;
    }

    public double getWinProbabilityBowling() {
        return 100.0 - winProbabilityBatting;
    }

    public String getExplanation() {
        return explanation;
    }

    @Override
    public String toString() {
        return "PredictionResult{projected=" + projectedScore +
                ", winProbBatting=" + String.format("%.1f", winProbabilityBatting) + "%" +
                ", explanation='" + explanation + "'}";
    }
}
