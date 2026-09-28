package com.cricket.view;

import com.cricket.model.*;
import com.cricket.service.MatchService;
import com.cricket.simulator.MatchSimulator;
import javafx.application.Platform;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;
import javafx.scene.control.Separator;
import javafx.scene.layout.*;

import java.util.List;

public class ScoreboardView extends BorderPane implements MatchService.MatchUpdateListener {

    private final MatchService matchService;

    // UI Header & Score components
    private final Label matchTitleLabel;
    private final Label statusBadge;
    private final Label scoreMainLabel;
    private final Label oversLabel;
    private final Label crrLabel;
    private final Label rrrLabel;
    private final Label targetLabel;

    // Batting & Bowling Stats Components
    private final Label strikerNameLabel;
    private final Label strikerStatsLabel;
    private final Label nonStrikerNameLabel;
    private final Label nonStrikerStatsLabel;
    private final Label bowlerNameLabel;
    private final Label bowlerFiguresLabel;

    // Components
    private final OverStripComponent overStrip;
    private final PredictionPanel predictionPanel;
    private final ControlPanel controlPanel;
    private final ListView<String> commentaryListView;

    public ScoreboardView(MatchService matchService, MatchSimulator matchSimulator) {
        this.matchService = matchService;
        this.matchService.addListener(this);

        this.setPadding(new Insets(20));
        this.setStyle("-fx-background-color: #0f172a;");

        // Top Header Box
        HBox headerBox = new HBox(16);
        headerBox.setAlignment(Pos.CENTER_LEFT);
        matchTitleLabel = new Label("INDIA vs AUSTRALIA — LIVE MATCH");
        matchTitleLabel.getStyleClass().add("match-title");

        statusBadge = new Label("1st Innings");
        statusBadge.getStyleClass().add("status-badge");

        Region headerSpacer = new Region();
        HBox.setHgrow(headerSpacer, Priority.ALWAYS);

        headerBox.getChildren().addAll(matchTitleLabel, statusBadge, headerSpacer);

        // Center Content Box (Main Scoreboard Grid + Prediction Panel)
        VBox centerBox = new VBox(16);

        // 1. Big Score Card
        VBox scoreCard = new VBox(12);
        scoreCard.getStyleClass().add("card-panel");

        HBox scoreRow = new HBox(20);
        scoreRow.setAlignment(Pos.BASELINE_LEFT);

        scoreMainLabel = new Label("0/0");
        scoreMainLabel.getStyleClass().add("score-main-text");

        oversLabel = new Label("(0.0 / 20 ov)");
        oversLabel.getStyleClass().add("overs-text");

        Region scoreSpacer = new Region();
        HBox.setHgrow(scoreSpacer, Priority.ALWAYS);

        crrLabel = new Label("CRR: 0.0");
        crrLabel.getStyleClass().add("runrate-label");

        rrrLabel = new Label("RRR: 0.0");
        rrrLabel.getStyleClass().add("target-label");
        rrrLabel.setVisible(false);

        targetLabel = new Label("Target: -");
        targetLabel.getStyleClass().add("target-label");
        targetLabel.setVisible(false);

        scoreRow.getChildren().addAll(scoreMainLabel, oversLabel, scoreSpacer, crrLabel, rrrLabel, targetLabel);

        // Batter & Bowler Stats Box
        GridPane statsGrid = new GridPane();
        statsGrid.setHgap(20);
        statsGrid.setVgap(10);
        statsGrid.setPadding(new Insets(8, 0, 8, 0));

        Label batHeader = new Label("BATSMEN");
        batHeader.getStyleClass().add("stats-header");
        Label bowlHeader = new Label("BOWLER");
        bowlHeader.getStyleClass().add("stats-header");

        statsGrid.add(batHeader, 0, 0, 2, 1);
        statsGrid.add(bowlHeader, 2, 0, 2, 1);

        strikerNameLabel = new Label("Striker *");
        strikerNameLabel.getStyleClass().add("player-name-striker");
        strikerStatsLabel = new Label("0 (0) [4s:0 6s:0 SR: 0.0]");
        strikerStatsLabel.getStyleClass().add("stat-value");

        nonStrikerNameLabel = new Label("Non-Striker");
        nonStrikerNameLabel.getStyleClass().add("player-name-normal");
        nonStrikerStatsLabel = new Label("0 (0) [4s:0 6s:0 SR: 0.0]");
        nonStrikerStatsLabel.getStyleClass().add("stat-value");

        bowlerNameLabel = new Label("Bowler");
        bowlerNameLabel.getStyleClass().add("player-name-normal");
        bowlerFiguresLabel = new Label("0-0 (0.0 ov) Econ: 0.0");
        bowlerFiguresLabel.getStyleClass().add("stat-value");

        statsGrid.add(strikerNameLabel, 0, 1);
        statsGrid.add(strikerStatsLabel, 1, 1);
        statsGrid.add(nonStrikerNameLabel, 0, 2);
        statsGrid.add(nonStrikerStatsLabel, 1, 2);

        statsGrid.add(bowlerNameLabel, 2, 1);
        statsGrid.add(bowlerFiguresLabel, 3, 1);

        // Over Strip
        overStrip = new OverStripComponent();

        scoreCard.getChildren().addAll(scoreRow, new Separator(), statsGrid, new Separator(), overStrip);

        // 2. Prediction Panel
        predictionPanel = new PredictionPanel();

        // 3. Control Panel (Manual entry & Simulator)
        controlPanel = new ControlPanel(matchService, matchSimulator);

        centerBox.getChildren().addAll(scoreCard, predictionPanel, controlPanel);

        // Right Content Box: Live Commentary Feed
        VBox rightBox = new VBox(10);
        rightBox.setPrefWidth(300);
        rightBox.getStyleClass().add("card-panel");

        Label commTitle = new Label("BALL-BY-BALL COMMENTARY");
        commTitle.getStyleClass().add("card-title");

        commentaryListView = new ListView<>();
        commentaryListView.getStyleClass().add("commentary-list");
        VBox.setVgrow(commentaryListView, Priority.ALWAYS);

        rightBox.getChildren().addAll(commTitle, commentaryListView);

        // Layout assembly
        VBox topContainer = new VBox(16);
        topContainer.getChildren().addAll(headerBox);

        this.setTop(topContainer);
        BorderPane.setMargin(topContainer, new Insets(0, 0, 16, 0));
        this.setCenter(centerBox);
        BorderPane.setMargin(centerBox, new Insets(0, 16, 0, 0));
        this.setRight(rightBox);

        // Refresh initially
        if (matchService.getCurrentMatch() != null) {
            refresh(matchService.getCurrentMatch(), matchService.getPredictionService().predict(matchService.getCurrentMatch()), null);
        }
    }

    /**
     * Primary refresh method to update display state from Match model.
     */
    public void refresh(Match match) {
        PredictionResult prediction = matchService.getPredictionService().predict(match);
        refresh(match, prediction, null);
    }

    public void refresh(Match match, PredictionResult prediction, Ball lastBall) {
        if (!Platform.isFxApplicationThread()) {
            Platform.runLater(() -> refresh(match, prediction, lastBall));
            return;
        }

        if (match == null) return;

        matchTitleLabel.setText(match.getTeam1Name().toUpperCase() + " vs " + match.getTeam2Name().toUpperCase());
        statusBadge.setText(match.getStatus().getDisplayName());

        Innings currentInnings = match.getCurrentInnings();
        scoreMainLabel.setText(currentInnings.getTotalRuns() + "/" + currentInnings.getTotalWickets());
        oversLabel.setText("(" + currentInnings.getOversFormatted() + " / " + match.getTotalOvers() + " ov)");

        crrLabel.setText("CRR: " + String.format("%.2f", currentInnings.getCurrentRunRate()));

        if (match.getStatus() == MatchStatus.SECOND_INNINGS) {
            rrrLabel.setText("RRR: " + String.format("%.2f", currentInnings.getRequiredRunRate()));
            rrrLabel.setVisible(true);
            targetLabel.setText("Target: " + match.getTargetRuns());
            targetLabel.setVisible(true);
        } else {
            rrrLabel.setVisible(false);
            targetLabel.setVisible(false);
        }

        // Update Batting Lineup Labels
        Player striker = currentInnings.getCurrentStriker();
        Player nonStriker = currentInnings.getCurrentNonStriker();
        Player bowler = currentInnings.getCurrentBowler();

        if (striker != null) {
            strikerNameLabel.setText(striker.getName() + " *");
            strikerStatsLabel.setText(String.format("%d (%d) [4s:%d 6s:%d SR: %.1f]",
                    striker.getRunsScored(), striker.getBallsFaced(), striker.getFours(), striker.getSixes(), striker.getStrikeRate()));
        }

        if (nonStriker != null) {
            nonStrikerNameLabel.setText(nonStriker.getName());
            nonStrikerStatsLabel.setText(String.format("%d (%d) [4s:%d 6s:%d SR: %.1f]",
                    nonStriker.getRunsScored(), nonStriker.getBallsFaced(), nonStriker.getFours(), nonStriker.getSixes(), nonStriker.getStrikeRate()));
        }

        if (bowler != null) {
            bowlerNameLabel.setText(bowler.getName());
            bowlerFiguresLabel.setText(String.format("%d-%d (%s ov) Econ: %.2f",
                    bowler.getBowlingWickets(), bowler.getBowlingRunsConceded(), bowler.getBowlingOversString(), bowler.getEconomyRate()));
        }

        // Update Over Strip
        overStrip.updateOver(currentInnings.getCurrentOverBalls());

        // Update Prediction Panel
        predictionPanel.updatePrediction(match, prediction);

        // Update Commentary List
        if (lastBall != null && lastBall.getCommentary() != null && !lastBall.getCommentary().isEmpty()) {
            String commEntry = String.format("[%d.%d] %s", lastBall.getOverNumber(), lastBall.getBallInOver(), lastBall.getCommentary());
            commentaryListView.getItems().add(0, commEntry);
        }

        if (match.getStatus() == MatchStatus.COMPLETED) {
            statusBadge.setText("FINAL: " + match.getResultSummary());
            statusBadge.setStyle("-fx-background-color: #22c55e; -fx-text-fill: #000;");
        }
    }

    @Override
    public void onMatchUpdated(Match match, PredictionResult prediction, Ball lastBall) {
        refresh(match, prediction, lastBall);
    }
}
