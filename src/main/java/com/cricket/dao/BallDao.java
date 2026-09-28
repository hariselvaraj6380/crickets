package com.cricket.dao;

import com.cricket.model.Ball;

import java.util.List;

public interface BallDao {
    int saveBall(Ball ball);
    List<Ball> getBallsByMatchAndOver(int matchId, int inningsNumber, int overNumber);
    List<Ball> getBallsForInnings(int matchId, int inningsNumber);
}
