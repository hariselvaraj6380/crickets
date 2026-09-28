package com.cricket;

import com.cricket.dao.*;
import com.cricket.model.*;
import com.cricket.prediction.HeuristicPredictionEngine;
import com.cricket.prediction.PredictionService;
import com.cricket.service.MatchService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class CricketScoreboardTest {

    private Match match;
    private MatchService matchService;
    private static final List<String> TEAM1 = Arrays.asList("Rohit", "Kohli", "Pant", "Hardik");
    private static final List<String> TEAM2 = Arrays.asList("Head", "Warner", "Marsh", "Cummins");

    @BeforeEach
    public void setUp() {
        DatabaseManager.initializeDatabase();
        match = new Match("India", "Australia", 20);
        PredictionService predictionService = new PredictionService(new HeuristicPredictionEngine());
        matchService = new MatchService(predictionService);
        matchService.startNewMatch(match, TEAM1, TEAM2);
    }

    @Test
    public void testInningsRecordBallAndScoreAggregation() {
        Innings innings = match.getFirstInnings();
        assertEquals(0, innings.getTotalRuns());
        assertEquals(0, innings.getTotalWickets());

        Ball b1 = new Ball(match.getId(), 1, 0, 1, "Head", "Rohit", "Kohli", 4, ExtraType.NONE, 0, WicketInfo.noWicket(), "Four!");
        innings.recordBall(b1);

        assertEquals(4, innings.getTotalRuns());
        assertEquals(0, innings.getTotalWickets());
        assertEquals(1, innings.getTotalLegalBalls());
        assertEquals("Rohit", innings.getCurrentStriker().getName()); // Four = even runs, no strike swap

        Ball b2 = new Ball(match.getId(), 1, 0, 2, "Head", "Rohit", "Kohli", 1, ExtraType.NONE, 0, WicketInfo.noWicket(), "Single");
        innings.recordBall(b2);

        assertEquals(5, innings.getTotalRuns());
        assertEquals("Kohli", innings.getCurrentStriker().getName()); // Single = odd runs, strike swapped!
    }

    @Test
    public void testWicketHandling() {
        Innings innings = match.getFirstInnings();
        Ball bWicket = new Ball(match.getId(), 1, 0, 1, "Head", "Rohit", "Kohli", 0, ExtraType.NONE, 0, WicketInfo.wicket(WicketType.BOWLED, "Rohit"), "Wicket!");
        innings.recordBall(bWicket);

        assertEquals(1, innings.getTotalWickets());
        assertTrue(innings.getPlayersMap().get("Rohit").isOut());
        assertEquals("Pant", innings.getCurrentStriker().getName()); // Next batter brought in
    }

    @Test
    public void testPredictionEngine1stInnings() {
        Innings innings = match.getFirstInnings();
        for (int i = 1; i <= 6; i++) {
            Ball b = new Ball(match.getId(), 1, 0, i, "Head", "Rohit", "Kohli", 2, ExtraType.NONE, 0, WicketInfo.noWicket(), "2 runs");
            innings.recordBall(b);
        }

        PredictionService service = new PredictionService(new HeuristicPredictionEngine());
        PredictionResult res = service.predict(match);

        assertNotNull(res);
        assertTrue(res.getProjectedScore() > 100);
        assertTrue(res.getExplanation().contains("Projected"));
    }

    @Test
    public void testDaoPersistenceAndIndexedQuery() {
        BallDao ballDao = new JdbcBallDao();

        Ball ball = new Ball(match.getId(), 1, 0, 1, "Head", "Rohit", "Kohli", 6, ExtraType.NONE, 0, WicketInfo.noWicket(), "SIX!");
        matchService.processBall(ball);

        List<Ball> fetchedBalls = ballDao.getBallsByMatchAndOver(match.getId(), 1, 0);
        assertNotNull(fetchedBalls);
        assertFalse(fetchedBalls.isEmpty());
        assertEquals(6, fetchedBalls.get(0).getRunsOffBat());
    }
}
