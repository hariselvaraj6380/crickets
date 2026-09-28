package com.cricket.dao;

import com.cricket.model.PredictionResult;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.logging.Level;
import java.util.logging.Logger;

public class JdbcPredictionDao implements PredictionDao {
    private static final Logger LOGGER = Logger.getLogger(JdbcPredictionDao.class.getName());

    @Override
    public void savePrediction(int matchId, int inningsNumber, int ballId, PredictionResult prediction) {
        String sql = "INSERT INTO predictions (match_id, innings_number, ball_id, projected_score, win_probability_batting, " +
                "explanation, calculated_at) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, matchId);
            ps.setInt(2, inningsNumber);
            ps.setInt(3, ballId);
            ps.setInt(4, prediction.getProjectedScore());
            ps.setDouble(5, prediction.getWinProbabilityBatting());
            ps.setString(6, prediction.getExplanation());
            ps.setTimestamp(7, Timestamp.valueOf(LocalDateTime.now()));

            ps.executeUpdate();
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error saving prediction snapshot: {0}", e.getMessage());
        }
    }
}
