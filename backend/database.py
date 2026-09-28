import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "cricket.db")

def get_connection():
    conn = sqlite3.connect(DB_PATH, timeout=10)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("PRAGMA journal_mode=WAL;")

    cursor.executescript("""
    CREATE TABLE IF NOT EXISTS matches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        team1_name TEXT NOT NULL,
        team2_name TEXT NOT NULL,
        total_overs INTEGER NOT NULL DEFAULT 20,
        status TEXT NOT NULL,
        target_runs INTEGER DEFAULT 0,
        winner_name TEXT,
        result_summary TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS innings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id INTEGER NOT NULL,
        innings_number INTEGER NOT NULL,
        batting_team TEXT NOT NULL,
        bowling_team TEXT NOT NULL,
        total_runs INTEGER DEFAULT 0,
        wickets INTEGER DEFAULT 0,
        legal_balls INTEGER DEFAULT 0,
        target_runs INTEGER DEFAULT 0,
        is_completed BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (match_id) REFERENCES matches(id)
    );

    CREATE TABLE IF NOT EXISTS balls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id INTEGER NOT NULL,
        innings_number INTEGER NOT NULL,
        over_number INTEGER NOT NULL,
        ball_in_over INTEGER NOT NULL,
        legal_ball_number INTEGER NOT NULL,
        bowler_name TEXT NOT NULL,
        batsman_name TEXT NOT NULL,
        non_striker_name TEXT NOT NULL,
        runs_off_bat INTEGER DEFAULT 0,
        extra_type TEXT DEFAULT 'NONE',
        extra_runs INTEGER DEFAULT 0,
        total_ball_runs INTEGER DEFAULT 0,
        is_wicket BOOLEAN DEFAULT FALSE,
        wicket_type TEXT DEFAULT 'NONE',
        dismissed_player TEXT,
        commentary TEXT,
        recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (match_id) REFERENCES matches(id)
    );

    CREATE TABLE IF NOT EXISTS predictions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id INTEGER NOT NULL,
        innings_number INTEGER NOT NULL,
        ball_id INTEGER DEFAULT 0,
        projected_score INTEGER DEFAULT 0,
        win_probability_batting REAL DEFAULT 50.0,
        explanation TEXT,
        calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (match_id) REFERENCES matches(id)
    );
    """)

    conn.commit()
    conn.close()

def save_ball_event(ball, prediction):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO balls (match_id, innings_number, over_number, ball_in_over, legal_ball_number,
                               bowler_name, batsman_name, non_striker_name, runs_off_bat, extra_type,
                               extra_runs, total_ball_runs, is_wicket, wicket_type, dismissed_player, commentary)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            ball.match_id, ball.innings_number, ball.over_number, ball.ball_in_over, ball.legal_ball_number,
            ball.bowler_name, ball.batsman_name, ball.non_striker_name, ball.runs_off_bat, ball.extra_type.value,
            ball.extra_runs, ball.get_total_runs(), ball.wicket_info.is_wicket(),
            ball.wicket_info.wicket_type.value, ball.wicket_info.dismissed_player, ball.commentary
        ))
        ball_id = cursor.lastrowid
        ball.id = ball_id

        if prediction:
            cursor.execute("""
                INSERT INTO predictions (match_id, innings_number, ball_id, projected_score, win_probability_batting, explanation)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                ball.match_id, ball.innings_number, ball_id, prediction.projected_score,
                prediction.win_probability_batting, prediction.explanation
            ))

        conn.commit()
    finally:
        conn.close()
