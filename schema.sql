-- Normalized MySQL Database Schema for Cricket Live Scoreboard & Predictions

CREATE TABLE IF NOT EXISTS matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    team1_name VARCHAR(100) NOT NULL,
    team2_name VARCHAR(100) NOT NULL,
    total_overs INT NOT NULL DEFAULT 20,
    status VARCHAR(30) NOT NULL,
    target_runs INT DEFAULT 0,
    winner_name VARCHAR(100) DEFAULT NULL,
    result_summary VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS players (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    team_name VARCHAR(100) NOT NULL,
    player_name VARCHAR(100) NOT NULL,
    runs_scored INT DEFAULT 0,
    balls_faced INT DEFAULT 0,
    fours INT DEFAULT 0,
    sixes INT DEFAULT 0,
    is_out BOOLEAN DEFAULT FALSE,
    bowling_legal_balls INT DEFAULT 0,
    bowling_runs_conceded INT DEFAULT 0,
    bowling_wickets INT DEFAULT 0,
    FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS innings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    innings_number INT NOT NULL,
    batting_team VARCHAR(100) NOT NULL,
    bowling_team VARCHAR(100) NOT NULL,
    total_runs INT DEFAULT 0,
    wickets INT DEFAULT 0,
    legal_balls INT DEFAULT 0,
    target_runs INT DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
    UNIQUE KEY uk_match_innings (match_id, innings_number)
);

CREATE TABLE IF NOT EXISTS balls (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    innings_number INT NOT NULL,
    over_number INT NOT NULL,
    ball_in_over INT NOT NULL,
    legal_ball_number INT NOT NULL,
    bowler_name VARCHAR(100) NOT NULL,
    batsman_name VARCHAR(100) NOT NULL,
    non_striker_name VARCHAR(100) NOT NULL,
    runs_off_bat INT DEFAULT 0,
    extra_type VARCHAR(20) DEFAULT 'NONE',
    extra_runs INT DEFAULT 0,
    total_ball_runs INT DEFAULT 0,
    is_wicket BOOLEAN DEFAULT FALSE,
    wicket_type VARCHAR(30) DEFAULT 'NONE',
    dismissed_player VARCHAR(100) DEFAULT NULL,
    commentary TEXT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
);

-- Fast live query index for ball-by-ball lookup per match and over
CREATE INDEX idx_balls_lookup ON balls (match_id, innings_number, over_number);

CREATE TABLE IF NOT EXISTS predictions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    match_id INT NOT NULL,
    innings_number INT NOT NULL,
    ball_id INT NOT NULL,
    projected_score INT DEFAULT 0,
    win_probability_batting DOUBLE DEFAULT 50.0,
    explanation TEXT,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
);
