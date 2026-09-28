package com.cricket.view;

import com.cricket.model.*;
import com.cricket.service.MatchService;
import com.cricket.simulator.MatchSimulator;
import javafx.collections.FXCollections;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.control.*;
import javafx.scene.layout.*;

public class ControlPanel extends VBox {

    private final MatchService matchService;
    private final MatchSimulator matchSimulator;

    private final ComboBox<ExtraType> extraTypeCombo;
    private final ComboBox<WicketType> wicketTypeCombo;
    private final TextField commentaryField;
    private final TextField runsField;

    private final Button startSimBtn;
    private final Button pauseSimBtn;
    private final Slider speedSlider;

    public ControlPanel(MatchService matchService, MatchSimulator matchSimulator) {
        this.matchService = matchService;
        this.matchSimulator = matchSimulator;

        this.getStyleClass().add("card-panel");
        this.setSpacing(14);

        Label title = new Label("LIVE MATCH CONTROL & SIMULATION");
        title.getStyleClass().add("card-title");

        // Quick Entry Buttons Row
        Label quickLabel = new Label("QUICK BALL ENTRY:");
        quickLabel.setStyle("-fx-font-size: 12px; -fx-font-weight: bold; -fx-text-fill: #94a3b8;");

        GridPane quickGrid = new GridPane();
        quickGrid.setHgap(8);
        quickGrid.setVgap(8);

        Button btnDot = createQuickButton("0", "secondary-btn", () -> recordQuickBall(0, ExtraType.NONE, WicketType.NONE));
        Button btn1 = createQuickButton("1", "action-btn", () -> recordQuickBall(1, ExtraType.NONE, WicketType.NONE));
        Button btn2 = createQuickButton("2", "action-btn", () -> recordQuickBall(2, ExtraType.NONE, WicketType.NONE));
        Button btn3 = createQuickButton("3", "action-btn", () -> recordQuickBall(3, ExtraType.NONE, WicketType.NONE));
        Button btn4 = createQuickButton("4 (FOUR)", "boundary-btn", () -> recordQuickBall(4, ExtraType.NONE, WicketType.NONE));
        Button btn6 = createQuickButton("6 (SIX)", "boundary-btn", () -> recordQuickBall(6, ExtraType.NONE, WicketType.NONE));
        Button btnWd = createQuickButton("Wide", "secondary-btn", () -> recordQuickBall(0, ExtraType.WIDE, WicketType.NONE));
        Button btnNb = createQuickButton("NoBall", "secondary-btn", () -> recordQuickBall(0, ExtraType.NO_BALL, WicketType.NONE));
        Button btnW = createQuickButton("WICKET", "wicket-btn", () -> recordQuickBall(0, ExtraType.NONE, WicketType.BOWLED));

        quickGrid.add(btnDot, 0, 0);
        quickGrid.add(btn1, 1, 0);
        quickGrid.add(btn2, 2, 0);
        quickGrid.add(btn3, 3, 0);
        quickGrid.add(btn4, 4, 0);
        quickGrid.add(btn6, 0, 1);
        quickGrid.add(btnWd, 1, 1);
        quickGrid.add(btnNb, 2, 1);
        quickGrid.add(btnW, 3, 1, 2, 1);

        // Detailed Ball Customization Row
        HBox customBox = new HBox(10);
        customBox.setAlignment(Pos.CENTER_LEFT);

        runsField = new TextField("0");
        runsField.setPrefWidth(50);
        runsField.setPromptText("Runs");

        extraTypeCombo = new ComboBox<>(FXCollections.observableArrayList(ExtraType.values()));
        extraTypeCombo.setValue(ExtraType.NONE);

        wicketTypeCombo = new ComboBox<>(FXCollections.observableArrayList(WicketType.values()));
        wicketTypeCombo.setValue(WicketType.NONE);

        commentaryField = new TextField();
        commentaryField.setPromptText("Optional commentary text...");
        HBox.setHgrow(commentaryField, Priority.ALWAYS);

        Button submitCustomBtn = new Button("Submit Delivery");
        submitCustomBtn.getStyleClass().add("action-btn");
        submitCustomBtn.setOnAction(e -> recordCustomBall());

        customBox.getChildren().addAll(
                new Label("Runs:"), runsField,
                new Label("Extra:"), extraTypeCombo,
                new Label("Wicket:"), wicketTypeCombo,
                commentaryField, submitCustomBtn
        );

        Separator separator = new Separator();
        separator.setStyle("-fx-background-color: #334155;");

        // Simulator Controls Row
        HBox simBox = new HBox(12);
        simBox.setAlignment(Pos.CENTER_LEFT);

        Label simTitle = new Label("MATCH SIMULATOR:");
        simTitle.setStyle("-fx-font-size: 13px; -fx-font-weight: bold; -fx-text-fill: #38bdf8;");

        startSimBtn = new Button("▶ Play Simulator");
        startSimBtn.getStyleClass().add("boundary-btn");
        startSimBtn.setOnAction(e -> {
            matchSimulator.start();
            updateSimButtons();
        });

        pauseSimBtn = new Button("⏸ Pause");
        pauseSimBtn.getStyleClass().add("secondary-btn");
        pauseSimBtn.setOnAction(e -> {
            matchSimulator.pause();
            updateSimButtons();
        });

        Button resetBtn = new Button("🔄 Reset Match");
        resetBtn.getStyleClass().add("wicket-btn");
        resetBtn.setOnAction(e -> {
            matchSimulator.stop();
            matchSimulator.resetNewMatch();
            updateSimButtons();
        });

        Label speedLabel = new Label("Speed:");
        speedLabel.setStyle("-fx-text-fill: #94a3b8;");

        speedSlider = new Slider(0.5, 5.0, 1.0);
        speedSlider.setPrefWidth(120);
        speedSlider.setShowTickMarks(true);
        speedSlider.setShowTickLabels(true);
        speedSlider.setMajorTickUnit(1.0);
        speedSlider.valueProperty().addListener((obs, oldV, newV) -> {
            matchSimulator.setSpeedMultiplier(newV.doubleValue());
        });

        simBox.getChildren().addAll(simTitle, startSimBtn, pauseSimBtn, resetBtn, speedLabel, speedSlider);

        this.getChildren().addAll(title, quickLabel, quickGrid, customBox, separator, simBox);
    }

    private Button createQuickButton(String text, String styleClass, Runnable action) {
        Button btn = new Button(text);
        btn.getStyleClass().add(styleClass);
        btn.setMaxWidth(Double.MAX_VALUE);
        btn.setOnAction(e -> action.run());
        return btn;
    }

    private void recordQuickBall(int runs, ExtraType extraType, WicketType wicketType) {
        Match match = matchService.getCurrentMatch();
        if (match == null || match.getStatus() == MatchStatus.COMPLETED) return;

        Innings innings = match.getCurrentInnings();
        Player striker = innings.getCurrentStriker();
        Player bowler = innings.getCurrentBowler();
        Player nonStriker = innings.getCurrentNonStriker();

        if (striker == null || bowler == null || nonStriker == null) return;

        int overNumber = (innings.getTotalLegalBalls() == 0) ? 0 :
                (innings.getTotalLegalBalls() % 6 == 0 && !extraType.isExtra() ? innings.getTotalLegalBalls() / 6 - 1 : innings.getTotalLegalBalls() / 6);
        int ballInOver = (innings.getTotalLegalBalls() % 6) + (extraType.isExtra() ? 0 : 1);

        WicketInfo wicketInfo = (wicketType != WicketType.NONE) ?
                WicketInfo.wicket(wicketType, striker.getName()) : WicketInfo.noWicket();

        String commentary = generateCommentary(striker.getName(), bowler.getName(), runs, extraType, wicketType);

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
                (extraType == ExtraType.WIDE || extraType == ExtraType.NO_BALL) ? 0 : 0,
                wicketInfo,
                commentary
        );

        matchService.processBall(ball);
    }

    private void recordCustomBall() {
        try {
            int runs = Integer.parseInt(runsField.getText().trim());
            ExtraType extra = extraTypeCombo.getValue();
            WicketType wicket = wicketTypeCombo.getValue();

            recordQuickBall(runs, extra, wicket);
            commentaryField.clear();
        } catch (NumberFormatException ex) {
            Alert alert = new Alert(Alert.AlertType.ERROR, "Invalid runs input. Please enter a valid number.");
            alert.show();
        }
    }

    private String generateCommentary(String striker, String bowler, int runs, ExtraType extra, WicketType wicket) {
        if (wicket.isWicket()) {
            return "OUT! " + bowler + " gets " + striker + " " + wicket.getDisplayName() + "!";
        }
        if (extra == ExtraType.WIDE) return "Wide ball from " + bowler;
        if (extra == ExtraType.NO_BALL) return "No ball from " + bowler;
        if (runs == 4) return "FOUR! Beautiful boundary by " + striker + " off " + bowler + "!";
        if (runs == 6) return "SIX! Huge strike by " + striker + " clears the boundary!";
        if (runs == 0) return "Dot ball. " + bowler + " to " + striker + ", no run.";
        return runs + " run" + (runs > 1 ? "s" : "") + " taken by " + striker + ".";
    }

    private void updateSimButtons() {
        boolean isRunning = matchSimulator.isRunning();
        startSimBtn.setDisable(isRunning);
        pauseSimBtn.setDisable(!isRunning);
    }
}
