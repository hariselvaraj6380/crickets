package com.cricket.dao;

import com.cricket.model.PredictionResult;

public interface PredictionDao {
    void savePrediction(int matchId, int inningsNumber, int ballId, PredictionResult prediction);
}
