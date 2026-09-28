package com.cricket.view;

import com.cricket.model.Ball;
import com.cricket.model.ExtraType;
import javafx.geometry.Pos;
import javafx.scene.control.Label;
import javafx.scene.layout.HBox;

import java.util.List;

public class OverStripComponent extends HBox {

    public OverStripComponent() {
        this.setSpacing(8);
        this.setAlignment(Pos.CENTER_LEFT);
    }

    public void updateOver(List<Ball> overBalls) {
        this.getChildren().clear();

        if (overBalls == null || overBalls.isEmpty()) {
            Label emptyLabel = new Label("This Over: -");
            emptyLabel.setStyle("-fx-text-fill: #64748b; -fx-font-size: 13px; -fx-font-style: italic;");
            this.getChildren().add(emptyLabel);
            return;
        }

        Label title = new Label("THIS OVER: ");
        title.setStyle("-fx-text-fill: #94a3b8; -fx-font-weight: bold; -fx-font-size: 12px;");
        this.getChildren().add(title);

        for (Ball ball : overBalls) {
            Label chip = createBallChip(ball);
            this.getChildren().add(chip);
        }
    }

    private Label createBallChip(Ball ball) {
        Label chip = new Label(ball.getChipText());
        chip.getStyleClass().add("over-chip");

        if (ball.getWicketInfo().isWicket()) {
            chip.getStyleClass().add("chip-wicket");
        } else if (ball.getExtraType().isExtra()) {
            chip.getStyleClass().add("chip-extra");
        } else if (ball.getRunsOffBat() == 4) {
            chip.getStyleClass().add("chip-four");
        } else if (ball.getRunsOffBat() == 6) {
            chip.getStyleClass().add("chip-six");
        } else if (ball.getRunsOffBat() == 0) {
            chip.getStyleClass().add("chip-dot");
        } else {
            chip.getStyleClass().add("chip-run");
        }

        return chip;
    }
}
