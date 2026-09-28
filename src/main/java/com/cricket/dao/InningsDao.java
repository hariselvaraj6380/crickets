package com.cricket.dao;

import com.cricket.model.Innings;

public interface InningsDao {
    int saveInnings(Innings innings);
    void updateInnings(Innings innings);
}
