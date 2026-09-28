package com.cricket.service;

import com.cricket.dao.*;
import com.cricket.model.Ball;
import com.cricket.model.Match;
import com.cricket.model.PredictionResult;
import com.cricket.prediction.PredictionService;

import java.util.ArrayList;
import java.util.List;

public class MatchService {
    private Match currentMatch;
    private final MatchDao matchDao;
    private final InningsDao inningsDao;
    private final BallDao ballDao;
    private final PredictionDao predictionDao;
    private final PredictionService predictionService;

    private final List<MatchUpdateListener> updateListeners;

    public interface MatchUpdateListener {
        void onMatchUpdated(Match match, PredictionResult prediction, Ball lastBall);
    }

    public MatchService(PredictionService predictionService) {
        this.matchDao = new JdbcMatchDao();
        this.inningsDao = new JdbcInningsDao();
        this.ballDao = new JdbcBallDao();
        this.predictionDao = new JdbcPredictionDao();
        this.predictionService = predictionService != null ? predictionService : new PredictionService();
        this.updateListeners = new ArrayList<>();
    }

    public MatchService(MatchDao matchDao, InningsDao inningsDao, BallDao ballDao,
                        PredictionDao predictionDao, PredictionService predictionService) {
        this.matchDao = matchDao;
        this.inningsDao = inningsDao;
        this.ballDao = ballDao;
        this.predictionDao = predictionDao;
        this.predictionService = predictionService;
        this.updateListeners = new ArrayList<>();
    }

    public void addListener(MatchUpdateListener listener) {
        if (listener != null && !updateListeners.contains(listener)) {
            updateListeners.add(listener);
        }
    }

    public void removeListener(MatchUpdateListener listener) {
        updateListeners.remove(listener);
    }

    public void startNewMatch(Match match, List<String> team1Players, List<String> team2Players) {
        this.currentMatch = match;
        int matchId = matchDao.saveMatch(match);
        if (matchId > 0) {
            match.setId(matchId);
        }

        match.getFirstInnings().setupPlayers(team1Players, team2Players);
        match.getSecondInnings().setupPlayers(team2Players, team1Players);

        inningsDao.saveInnings(match.getFirstInnings());
        inningsDao.saveInnings(match.getSecondInnings());

        PredictionResult initialPrediction = predictionService.predict(match);
        notifyListeners(match, initialPrediction, null);
    }

    /**
     * Strict 4-step live update flow:
     * 1. innings.recordBall(ball)
     * 2. DAO persists ball, innings, & match state
     * 3. predictionService.predict(match) & DAO saves snapshot
     * 4. scoreboardView.refresh(match) via listener notification
     */
    public synchronized void processBall(Ball ball) {
        if (currentMatch == null) return;

        // Stage 1: Record ball in domain model
        currentMatch.getCurrentInnings().recordBall(ball);
        currentMatch.updateMatchState();

        // Stage 2: Persist via DAOs
        ballDao.saveBall(ball);
        inningsDao.updateInnings(currentMatch.getCurrentInnings());
        matchDao.updateMatchStatus(currentMatch);

        // Stage 3: Generate and persist prediction snapshot
        PredictionResult prediction = predictionService.predict(currentMatch);
        predictionDao.savePrediction(currentMatch.getId(), ball.getInningsNumber(), ball.getId(), prediction);

        // Stage 4: Trigger UI Refresh
        notifyListeners(currentMatch, prediction, ball);
    }

    private void notifyListeners(Match match, PredictionResult prediction, Ball lastBall) {
        for (MatchUpdateListener listener : updateListeners) {
            listener.onMatchUpdated(match, prediction, lastBall);
        }
    }

    public Match getCurrentMatch() {
        return currentMatch;
    }

    public PredictionService getPredictionService() {
        return predictionService;
    }
}
