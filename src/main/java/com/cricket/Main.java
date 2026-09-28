package com.cricket;

import com.cricket.dao.DatabaseManager;
import com.cricket.prediction.HeuristicPredictionEngine;
import com.cricket.prediction.PredictionService;
import com.cricket.service.MatchService;
import com.cricket.simulator.MatchSimulator;
import com.cricket.view.ScoreboardView;
import javafx.application.Application;
import javafx.scene.Scene;
import javafx.stage.Stage;

import java.util.logging.Logger;

import com.cricket.api.CricketHttpServer;

public class Main extends Application {
    private static final Logger LOGGER = Logger.getLogger(Main.class.getName());
    private static CricketHttpServer httpServer;

    @Override
    public void start(Stage primaryStage) {
        LOGGER.info("Starting Cricket Live Scoreboard Application...");

        // 1. Initialize Database Schema (MySQL with H2 fallback)
        DatabaseManager.initializeDatabase();

        // 2. Initialize Services & Engine
        PredictionService predictionService = new PredictionService(new HeuristicPredictionEngine());
        MatchService matchService = new MatchService(predictionService);
        MatchSimulator matchSimulator = new MatchSimulator(matchService);

        // 3. Initialize default simulation match
        matchSimulator.resetNewMatch();

        // 4. Start REST API Server on port 8080
        try {
            httpServer = new CricketHttpServer(8080, matchService, matchSimulator);
            httpServer.start();
        } catch (Exception e) {
            LOGGER.severe("Failed to start REST API server: " + e.getMessage());
        }

        // 5. Build JavaFX Main View
        ScoreboardView mainView = new ScoreboardView(matchService, matchSimulator);

        Scene scene = new Scene(mainView, 1280, 850);
        try {
            scene.getStylesheets().add(getClass().getResource("/styles/scoreboard.css").toExternalForm());
        } catch (Exception e) {
            LOGGER.warning("Could not load stylesheet: " + e.getMessage());
        }

        primaryStage.setTitle("Cricket Live Scoreboard with Ball-by-Ball Prediction Engine");
        primaryStage.setScene(scene);
        primaryStage.setMinWidth(1100);
        primaryStage.setMinHeight(750);
        primaryStage.setOnCloseRequest(e -> {
            if (httpServer != null) httpServer.stop();
            matchSimulator.stop();
            System.exit(0);
        });
        primaryStage.show();
    }

    public static void main(String[] args) {
        if (args != null && args.length > 0 && "--server-only".equalsIgnoreCase(args[0])) {
            LOGGER.info("Starting Cricket REST API Server in headless mode...");
            DatabaseManager.initializeDatabase();
            PredictionService predictionService = new PredictionService(new HeuristicPredictionEngine());
            MatchService matchService = new MatchService(predictionService);
            MatchSimulator matchSimulator = new MatchSimulator(matchService);
            matchSimulator.resetNewMatch();
            try {
                httpServer = new CricketHttpServer(8080, matchService, matchSimulator);
                httpServer.start();
                LOGGER.info("REST API Server ready on http://localhost:8080/api/match/status");
                Thread.currentThread().join();
            } catch (Exception e) {
                LOGGER.severe("Error running headless server: " + e.getMessage());
            }
        } else {
            launch(args);
        }
    }
}
