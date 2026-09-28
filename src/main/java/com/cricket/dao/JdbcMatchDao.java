package com.cricket.dao;

import com.cricket.model.Match;
import com.cricket.model.MatchStatus;

import java.sql.*;
import java.util.logging.Level;
import java.util.logging.Logger;

public class JdbcMatchDao implements MatchDao {
    private static final Logger LOGGER = Logger.getLogger(JdbcMatchDao.class.getName());

    @Override
    public int saveMatch(Match match) {
        String sql = "INSERT INTO matches (team1_name, team2_name, total_overs, status, target_runs, winner_name, result_summary) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1, match.getTeam1Name());
            ps.setString(2, match.getTeam2Name());
            ps.setInt(3, match.getTotalOvers());
            ps.setString(4, match.getStatus().name());
            ps.setInt(5, match.getTargetRuns());
            ps.setString(6, match.getWinnerName());
            ps.setString(7, match.getResultSummary());

            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    int generatedId = rs.getInt(1);
                    match.setId(generatedId);
                    return generatedId;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error saving match: {0}", e.getMessage());
        }
        return -1;
    }

    @Override
    public void updateMatchStatus(Match match) {
        String sql = "UPDATE matches SET status = ?, target_runs = ?, winner_name = ?, result_summary = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, match.getStatus().name());
            ps.setInt(2, match.getTargetRuns());
            ps.setString(3, match.getWinnerName());
            ps.setString(4, match.getResultSummary());
            ps.setInt(5, match.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error updating match status: {0}", e.getMessage());
        }
    }

    @Override
    public Match getMatchById(int matchId) {
        String sql = "SELECT * FROM matches WHERE id = ?";
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, matchId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Match match = new Match(
                            rs.getString("team1_name"),
                            rs.getString("team2_name"),
                            rs.getInt("total_overs")
                    );
                    match.setId(rs.getInt("id"));
                    match.setStatus(MatchStatus.valueOf(rs.getString("status")));
                    match.setTargetRuns(rs.getInt("target_runs"));
                    return match;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error retrieving match: {0}", e.getMessage());
        }
        return null;
    }
}
