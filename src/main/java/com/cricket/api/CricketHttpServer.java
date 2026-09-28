package com.cricket.api;

import com.cricket.model.*;
import com.cricket.prediction.PredictionService;
import com.cricket.service.MatchService;
import com.cricket.simulator.MatchSimulator;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.logging.Logger;

public class CricketHttpServer {
    private static final Logger LOGGER = Logger.getLogger(CricketHttpServer.class.getName());
    private final int port;
    private final MatchService matchService;
    private final MatchSimulator matchSimulator;
    private final Gson gson;
    private HttpServer server;

    public CricketHttpServer(int port, MatchService matchService, MatchSimulator matchSimulator) {
        this.port = port;
        this.matchService = matchService;
        this.matchSimulator = matchSimulator;
        this.gson = new GsonBuilder().setPrettyPrinting().create();
    }

    public void start() throws IOException {
        server = HttpServer.create(new InetSocketAddress(port), 0);

        server.createContext("/api/match/status", new StatusHandler());
        server.createContext("/api/match/scorecard", new ScorecardHandler());
        server.createContext("/api/match/sim/play", new SimPlayHandler());
        server.createContext("/api/match/sim/pause", new SimPauseHandler());
        server.createContext("/api/match/sim/step", new SimStepHandler());
        server.createContext("/api/match/sim/reset", new SimResetHandler());
        server.createContext("/api/match/sim/speed", new SimSpeedHandler());
        server.createContext("/api/match/sim/ball", new SimBallInjectHandler());

        server.setExecutor(java.util.concurrent.Executors.newCachedThreadPool());
        server.start();
        LOGGER.info("Cricket REST API Server running on port " + port);
    }

    public void stop() {
        if (server != null) {
            server.stop(0);
        }
    }

    private void sendJsonResponse(HttpExchange exchange, int statusCode, Object data) throws IOException {
        addCorsHeaders(exchange);
        if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
            exchange.sendResponseHeaders(204, -1);
            return;
        }

        String json = gson.toJson(data);
        byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
        exchange.sendResponseHeaders(statusCode, bytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
    }

    private void addCorsHeaders(HttpExchange exchange) {
        exchange.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
        exchange.getResponseHeaders().set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        exchange.getResponseHeaders().set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    }

    private Map<String, Object> buildStatusResponse() {
        Map<String, Object> map = new LinkedHashMap<>();
        Match match = matchService.getCurrentMatch();
        if (match == null) {
            map.put("error", "No active match");
            return map;
        }

        Innings currInnings = match.getCurrentInnings();
        PredictionService predService = matchService.getPredictionService();
        PredictionResult pred = predService != null ? predService.predict(match) : new PredictionResult(0, 50.0, "Initial state");

        map.put("matchId", match.getId());
        map.put("team1", match.getTeam1Name());
        map.put("team2", match.getTeam2Name());
        map.put("totalOvers", match.getTotalOvers());
        map.put("status", match.getStatus().toString());
        map.put("targetRuns", match.getTargetRuns());
        map.put("winnerName", match.getWinnerName());
        map.put("resultSummary", match.getResultSummary());

        map.put("currentInningsNumber", currInnings.getInningsNumber());
        map.put("battingTeam", currInnings.getBattingTeam());
        map.put("bowlingTeam", currInnings.getBowlingTeam());
        map.put("totalRuns", currInnings.getTotalRuns());
        map.put("wickets", currInnings.getTotalWickets());
        map.put("legalBalls", currInnings.getTotalLegalBalls());
        map.put("oversFormatted", currInnings.getOversFormatted());
        map.put("currentRunRate", Math.round(currInnings.getCurrentRunRate() * 100.0) / 100.0);
        map.put("requiredRunRate", Math.round(currInnings.getRequiredRunRate() * 100.0) / 100.0);

        // Simulation state
        map.put("isSimulating", matchSimulator.isRunning());
        map.put("speedMultiplier", matchSimulator.getSpeedMultiplier());

        // Current Players
        Player striker = currInnings.getCurrentStriker();
        Player nonStriker = currInnings.getCurrentNonStriker();
        Player bowler = currInnings.getCurrentBowler();

        if (striker != null) {
            Map<String, Object> sMap = new HashMap<>();
            sMap.put("name", striker.getName());
            sMap.put("runs", striker.getRunsScored());
            sMap.put("balls", striker.getBallsFaced());
            sMap.put("fours", striker.getFours());
            sMap.put("sixes", striker.getSixes());
            sMap.put("strikeRate", Math.round(striker.getStrikeRate() * 100.0) / 100.0);
            map.put("striker", sMap);
        }

        if (nonStriker != null) {
            Map<String, Object> nsMap = new HashMap<>();
            nsMap.put("name", nonStriker.getName());
            nsMap.put("runs", nonStriker.getRunsScored());
            nsMap.put("balls", nonStriker.getBallsFaced());
            nsMap.put("fours", nonStriker.getFours());
            nsMap.put("sixes", nonStriker.getSixes());
            nsMap.put("strikeRate", Math.round(nonStriker.getStrikeRate() * 100.0) / 100.0);
            map.put("nonStriker", nsMap);
        }

        if (bowler != null) {
            Map<String, Object> bMap = new HashMap<>();
            bMap.put("name", bowler.getName());
            bMap.put("overs", bowler.getBowlingOversString());
            bMap.put("runsConceded", bowler.getBowlingRunsConceded());
            bMap.put("wickets", bowler.getBowlingWickets());
            bMap.put("economy", Math.round(bowler.getEconomyRate() * 100.0) / 100.0);
            map.put("bowler", bMap);
        }

        // Win Prediction
        Map<String, Object> predMap = new HashMap<>();
        String favoredTeam = (pred.getWinProbabilityBatting() >= 50.0) ? currInnings.getBattingTeam() : currInnings.getBowlingTeam();
        predMap.put("favoredTeam", favoredTeam);
        predMap.put("winProbabilityTeam1", Math.round(pred.getWinProbabilityBatting() * 10.0) / 10.0);
        predMap.put("winProbabilityTeam2", Math.round(pred.getWinProbabilityBowling() * 10.0) / 10.0);
        predMap.put("projectedScore", pred.getProjectedScore());
        predMap.put("explanation", pred.getExplanation());
        map.put("prediction", predMap);

        // Recent balls in current over
        List<Ball> recordedBalls = currInnings.getRecordedBalls();
        List<Map<String, Object>> recentBalls = new ArrayList<>();
        int startIdx = Math.max(0, recordedBalls.size() - 14);
        for (int i = startIdx; i < recordedBalls.size(); i++) {
            Ball b = recordedBalls.get(i);
            Map<String, Object> bMap = new HashMap<>();
            bMap.put("ballId", b.getId());
            bMap.put("overNumber", b.getOverNumber());
            bMap.put("ballInOver", b.getBallInOver());
            bMap.put("displayLabel", b.getChipText());
            bMap.put("commentary", b.getCommentary());
            bMap.put("runsOffBat", b.getRunsOffBat());
            bMap.put("isWicket", b.getWicketInfo().isWicket());
            recentBalls.add(bMap);
        }
        map.put("recentBalls", recentBalls);

        return map;
    }

    private class StatusHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendJsonResponse(exchange, 204, null);
                return;
            }
            sendJsonResponse(exchange, 200, buildStatusResponse());
        }
    }

    private class ScorecardHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendJsonResponse(exchange, 204, null);
                return;
            }

            Match match = matchService.getCurrentMatch();
            if (match == null) {
                sendJsonResponse(exchange, 404, Map.of("error", "No active match"));
                return;
            }

            Map<String, Object> response = new LinkedHashMap<>();
            response.put("matchId", match.getId());
            response.put("status", match.getStatus().toString());

            List<Map<String, Object>> inningsList = new ArrayList<>();
            for (Innings inn : Arrays.asList(match.getFirstInnings(), match.getSecondInnings())) {
                Map<String, Object> innMap = new LinkedHashMap<>();
                innMap.put("inningsNumber", inn.getInningsNumber());
                innMap.put("battingTeam", inn.getBattingTeam());
                innMap.put("bowlingTeam", inn.getBowlingTeam());
                innMap.put("totalRuns", inn.getTotalRuns());
                innMap.put("wickets", inn.getTotalWickets());
                innMap.put("oversFormatted", inn.getOversFormatted());

                // Batting table
                List<Map<String, Object>> batters = new ArrayList<>();
                for (Player p : inn.getPlayersMap().values()) {
                    if (p.getTeamName().equalsIgnoreCase(inn.getBattingTeam()) && (p.getBallsFaced() > 0 || p.isOut() || p.getName().equals(inn.getCurrentStriker() != null ? inn.getCurrentStriker().getName() : "") || p.getName().equals(inn.getCurrentNonStriker() != null ? inn.getCurrentNonStriker().getName() : ""))) {
                        Map<String, Object> pMap = new HashMap<>();
                        pMap.put("name", p.getName());
                        pMap.put("runs", p.getRunsScored());
                        pMap.put("balls", p.getBallsFaced());
                        pMap.put("fours", p.getFours());
                        pMap.put("sixes", p.getSixes());
                        pMap.put("strikeRate", Math.round(p.getStrikeRate() * 100.0) / 100.0);
                        pMap.put("isOut", p.isOut());
                        pMap.put("dismissalInfo", p.getDismissalInfo());
                        batters.add(pMap);
                    }
                }
                innMap.put("batters", batters);

                // Bowling table
                List<Map<String, Object>> bowlers = new ArrayList<>();
                for (Player p : inn.getPlayersMap().values()) {
                    if (p.getTeamName().equalsIgnoreCase(inn.getBowlingTeam()) && p.getBowlingLegalBalls() > 0) {
                        Map<String, Object> bMap = new HashMap<>();
                        bMap.put("name", p.getName());
                        bMap.put("overs", p.getBowlingOversString());
                        bMap.put("runsConceded", p.getBowlingRunsConceded());
                        bMap.put("wickets", p.getBowlingWickets());
                        bMap.put("economy", Math.round(p.getEconomyRate() * 100.0) / 100.0);
                        bowlers.add(bMap);
                    }
                }
                innMap.put("bowlers", bowlers);
                inningsList.add(innMap);
            }

            response.put("innings", inningsList);
            sendJsonResponse(exchange, 200, response);
        }
    }

    private class SimPlayHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendJsonResponse(exchange, 204, null);
                return;
            }
            matchSimulator.start();
            sendJsonResponse(exchange, 200, Map.of("message", "Simulation started", "isSimulating", matchSimulator.isRunning()));
        }
    }

    private class SimPauseHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendJsonResponse(exchange, 204, null);
                return;
            }
            matchSimulator.pause();
            sendJsonResponse(exchange, 200, Map.of("message", "Simulation paused", "isSimulating", matchSimulator.isRunning()));
        }
    }

    private class SimStepHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendJsonResponse(exchange, 204, null);
                return;
            }
            matchSimulator.stepSingleBall();
            sendJsonResponse(exchange, 200, buildStatusResponse());
        }
    }

    private class SimResetHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendJsonResponse(exchange, 204, null);
                return;
            }
            matchSimulator.resetNewMatch();
            sendJsonResponse(exchange, 200, buildStatusResponse());
        }
    }

    private class SimSpeedHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendJsonResponse(exchange, 204, null);
                return;
            }
            if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                InputStreamReader reader = new InputStreamReader(exchange.getRequestBody(), StandardCharsets.UTF_8);
                Map body = gson.fromJson(reader, Map.class);
                if (body != null && body.containsKey("multiplier")) {
                    double mult = Double.parseDouble(body.get("multiplier").toString());
                    matchSimulator.setSpeedMultiplier(mult);
                }
            }
            sendJsonResponse(exchange, 200, Map.of("speedMultiplier", matchSimulator.getSpeedMultiplier()));
        }
    }

    private class SimBallInjectHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendJsonResponse(exchange, 204, null);
                return;
            }
            if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                InputStreamReader reader = new InputStreamReader(exchange.getRequestBody(), StandardCharsets.UTF_8);
                Map body = gson.fromJson(reader, Map.class);
                if (body != null) {
                    int runs = body.containsKey("runs") ? ((Number) body.get("runs")).intValue() : 0;
                    String extra = body.containsKey("extraType") ? body.get("extraType").toString() : "NONE";
                    String wicket = body.containsKey("wicketType") ? body.get("wicketType").toString() : "NONE";
                    matchSimulator.injectCustomBall(runs, extra, wicket);
                }
            }
            sendJsonResponse(exchange, 200, buildStatusResponse());
        }
    }
}
