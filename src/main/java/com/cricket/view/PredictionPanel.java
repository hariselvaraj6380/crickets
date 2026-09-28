package com.cricket.view;

import com.cricket.model.Match;
import com.cricket.model.MatchStatus;
import com.cricket.model.PredictionResult;
import javafx.geometry.Pos;
import javafx.scene.control.Label;
import javafx.scene.control.Tooltip;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.scene.layout.Region;
import javafx.scene.layout.VBox;

public class PredictionPanel extends VBox {

    private final Label titleLabel;
    private final Label projectedScoreLabel;
    private final Label battingTeamProbLabel;
    private final Label bowlingTeamProbLabel;
    private final Region battingBar;
    private final Region bowlingBar;
    private final HBox winBarContainer;
    private final Label explanationLabel;

    public PredictionPanel() {
        this.getStyleClass().add("card-panel");
        this.setSpacing(12);

        titleLabel = new Label("BALL-BY-BALL PREDICTION ENGINE");
        titleLabel.getStyleClass().add("prediction-title");

        // Projected Score Line
        HBox projectedBox = new HBox(10);
        projectedBox.setAlignment(Pos.CENTER_LEFT);
        Label projTitle = new Label("PROJECTED TOTAL:");
        projTitle.setStyle("-fx-font-size: 14px; -fx-font-weight: bold; -fx-text-fill: #94a3b8;");
        projectedScoreLabel = new Label("-");
        projectedScoreLabel.getStyleClass().add("projected-val");
        projectedBox.getChildren().addAll(projTitle, projectedScoreLabel);

        // Win Probability Labels & Bar
        HBox probLabelsBox = new HBox();
        battingTeamProbLabel = new Label("Batting: 50.0%");
        battingTeamProbLabel.setStyle("-fx-font-weight: bold; -fx-text-fill: #38bdf8; -fx-font-size: 13px;");
        Region spacer = new Region();
        HBox.setHgrow(spacer, Priority.ALWAYS);
        bowlingTeamProbLabel = new Label("Bowling: 50.0%");
        bowlingTeamProbLabel.setStyle("-fx-font-weight: bold; -fx-text-fill: #fb7185; -fx-font-size: 13px;");
        probLabelsBox.getChildren().addAll(battingTeamProbLabel, spacer, bowlingTeamProbLabel);

        winBarContainer = new HBox();
        winBarContainer.setPrefHeight(14);
        winBarContainer.setMaxHeight(14);
        winBarContainer.setStyle("-fx-background-color: #334155; -fx-background-radius: 6px;");

        battingBar = new Region();
        battingBar.getStyleClass().add("win-bar-batting");
        bowlingBar = new Region();
        bowlingBar.getStyleClass().add("win-bar-bowling");
        winBarContainer.getChildren().addAll(battingBar, bowlingBar);

        // Explanation text pill
        explanationLabel = new Label("Awaiting match progress...");
        explanationLabel.getStyleClass().add("prediction-explanation");
        explanationLabel.setMaxWidth(Double.MAX_VALUE);
        explanationLabel.setWrapText(true);

        this.getChildren().addAll(titleLabel, projectedBox, probLabelsBox, winBarContainer, explanationLabel);
    }

    public void updatePrediction(Match match, PredictionResult prediction) {
        if (prediction == null || match == null) return;

        projectedScoreLabel.setText(String.valueOf(prediction.getProjectedScore()));
        explanationLabel.setText("💡 " + prediction.getExplanation());

        double batProb = prediction.getWinProbabilityBatting();
        double bowlProb = prediction.getWinProbabilityBowling();

        String battingTeam = (match.getStatus() == MatchStatus.SECOND_INNINGS) ? match.getTeam2Name() : match.getTeam1Name();
        String bowlingTeam = (match.getStatus() == MatchStatus.SECOND_INNINGS) ? match.getTeam1Name() : match.getTeam2Name();

        battingTeamProbLabel.setText(battingTeam + ": " + String.format("%.1f", batProb) + "%");
        bowlingTeamProbLabel.setText(bowlingTeam + ": " + String.format("%.1f", bowlProb) + "%");

        // Update bar widths proportionally
        double totalWidth = Math.max(winBarContainer.getWidth(), 300);
        double batWidth = totalWidth * (batProb / 100.0);
        double bowlWidth = totalWidth * (bowlProb / 100.0);

        battingBar.setPrefWidth(batWidth);
        bowlingBar.setPrefWidth(bowlWidth);
    }
}
