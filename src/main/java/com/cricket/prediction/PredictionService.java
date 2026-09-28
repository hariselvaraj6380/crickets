package com.cricket.prediction;

import com.cricket.model.Match;
import com.cricket.model.PredictionResult;

public class PredictionService {
    private PredictionEngine engine;

    public PredictionService() {
        this.engine = new HeuristicPredictionEngine();
    }

    public PredictionService(PredictionEngine engine) {
        this.engine = engine;
    }

    public void setEngine(PredictionEngine engine) {
        this.engine = engine;
    }

    public PredictionResult predict(Match match) {
        return engine.predict(match);
    }
}
