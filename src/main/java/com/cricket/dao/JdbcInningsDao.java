package com.cricket.dao;

import com.cricket.model.Innings;

import java.sql.*;
import java.util.logging.Level;
import java.util.logging.Logger;

public class JdbcInningsDao implements InningsDao {
    private static final Logger LOGGER = Logger.getLogger(JdbcInningsDao.class.getName());

    @Override
    public int saveInnings(Innings innings) {
        String sql = "INSERT INTO innings (match_id, innings_number, batting_team, bowling_team, total_runs, wickets, legal_balls, target_runs, is_completed) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, innings.getMatchId());
            ps.setInt(2, innings.getInningsNumber());
            ps.setString(3, innings.getBattingTeam());
            ps.setString(4, innings.getBowlingTeam());
            ps.setInt(5, innings.getTotalRuns());
            ps.setInt(6, innings.getTotalWickets());
            ps.setInt(7, innings.getTotalLegalBalls());
            ps.setInt(8, innings.getTargetRuns());
            ps.setBoolean(9, innings.isCompleted());

            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    int generatedId = rs.getInt(1);
                    innings.setId(generatedId);
                    return generatedId;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error saving innings: {0}", e.getMessage());
        }
        return -1;
    }

    @Override
    public void updateInnings(Innings innings) {
        String sql = "UPDATE innings SET total_runs = ?, wickets = ?, legal_balls = ?, target_runs = ?, is_completed = ? " +
                "WHERE match_id = ? AND innings_number = ?";
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, innings.getTotalRuns());
            ps.setInt(2, innings.getTotalWickets());
            ps.setInt(3, innings.getTotalLegalBalls());
            ps.setInt(4, innings.getTargetRuns());
            ps.setBoolean(5, innings.isCompleted());
            ps.setInt(6, innings.getMatchId());
            ps.setInt(7, innings.getInningsNumber());

            ps.executeUpdate();
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error updating innings: {0}", e.getMessage());
        }
    }
}
