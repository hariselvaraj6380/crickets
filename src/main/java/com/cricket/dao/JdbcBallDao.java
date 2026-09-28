package com.cricket.dao;

import com.cricket.model.Ball;
import com.cricket.model.ExtraType;
import com.cricket.model.WicketInfo;
import com.cricket.model.WicketType;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class JdbcBallDao implements BallDao {
    private static final Logger LOGGER = Logger.getLogger(JdbcBallDao.class.getName());

    @Override
    public int saveBall(Ball ball) {
        String sql = "INSERT INTO balls (match_id, innings_number, over_number, ball_in_over, legal_ball_number, bowler_name, " +
                "batsman_name, non_striker_name, runs_off_bat, extra_type, extra_runs, total_ball_runs, is_wicket, wicket_type, " +
                "dismissed_player, commentary, recorded_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, ball.getMatchId());
            ps.setInt(2, ball.getInningsNumber());
            ps.setInt(3, ball.getOverNumber());
            ps.setInt(4, ball.getBallInOver());
            ps.setInt(5, ball.getLegalBallNumber());
            ps.setString(6, ball.getBowlerName());
            ps.setString(7, ball.getBatsmanName());
            ps.setString(8, ball.getNonStrikerName());
            ps.setInt(9, ball.getRunsOffBat());
            ps.setString(10, ball.getExtraType().name());
            ps.setInt(11, ball.getExtraRuns());
            ps.setInt(12, ball.getTotalRuns());
            ps.setBoolean(13, ball.getWicketInfo().isWicket());
            ps.setString(14, ball.getWicketInfo().getType().name());
            ps.setString(15, ball.getWicketInfo().getDismissedPlayer());
            ps.setString(16, ball.getCommentary());
            ps.setTimestamp(17, Timestamp.valueOf(ball.getRecordedAt()));

            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    int generatedId = rs.getInt(1);
                    ball.setId(generatedId);
                    return generatedId;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error saving ball delivery: {0}", e.getMessage());
        }
        return -1;
    }

    @Override
    public List<Ball> getBallsByMatchAndOver(int matchId, int inningsNumber, int overNumber) {
        // Leverages idx_balls_lookup ON balls (match_id, innings_number, over_number)
        String sql = "SELECT * FROM balls WHERE match_id = ? AND innings_number = ? AND over_number = ? ORDER BY id ASC";
        List<Ball> balls = new ArrayList<>();
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, matchId);
            ps.setInt(2, inningsNumber);
            ps.setInt(3, overNumber);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    balls.add(mapResultSetToBall(rs));
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error fetching balls by over: {0}", e.getMessage());
        }
        return balls;
    }

    @Override
    public List<Ball> getBallsForInnings(int matchId, int inningsNumber) {
        String sql = "SELECT * FROM balls WHERE match_id = ? AND innings_number = ? ORDER BY id ASC";
        List<Ball> balls = new ArrayList<>();
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, matchId);
            ps.setInt(2, inningsNumber);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    balls.add(mapResultSetToBall(rs));
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error fetching balls for innings: {0}", e.getMessage());
        }
        return balls;
    }

    private Ball mapResultSetToBall(ResultSet rs) throws SQLException {
        boolean isWicket = rs.getBoolean("is_wicket");
        WicketType wicketType = WicketType.valueOf(rs.getString("wicket_type"));
        String dismissed = rs.getString("dismissed_player");
        WicketInfo wicketInfo = isWicket ? WicketInfo.wicket(wicketType, dismissed) : WicketInfo.noWicket();

        Ball ball = new Ball(
                rs.getInt("match_id"),
                rs.getInt("innings_number"),
                rs.getInt("over_number"),
                rs.getInt("ball_in_over"),
                rs.getString("bowler_name"),
                rs.getString("batsman_name"),
                rs.getString("non_striker_name"),
                rs.getInt("runs_off_bat"),
                ExtraType.valueOf(rs.getString("extra_type")),
                rs.getInt("extra_runs"),
                wicketInfo,
                rs.getString("commentary")
        );
        ball.setId(rs.getInt("id"));
        ball.setLegalBallNumber(rs.getInt("legal_ball_number"));
        Timestamp ts = rs.getTimestamp("recorded_at");
        if (ts != null) {
            ball.setRecordedAt(ts.toLocalDateTime());
        }
        return ball;
    }
}
