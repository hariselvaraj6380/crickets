package com.cricket.dao;

import com.cricket.model.Match;

public interface MatchDao {
    int saveMatch(Match match);
    void updateMatchStatus(Match match);
    Match getMatchById(int matchId);
}
