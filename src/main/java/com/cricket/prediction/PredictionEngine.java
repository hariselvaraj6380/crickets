package com.cricket.prediction;

import com.cricket.model.Match;
import com.cricket.model.PredictionResult;

public interface PredictionEngine {
    /**
     * Calculates the ball-by-ball prediction snapshot for the given match state.
     *
     * @param match The current match state
     * @return PredictionResult containing projected score, win probability %, and explanation
     */
    PredictionResult predict(Match match);
}
