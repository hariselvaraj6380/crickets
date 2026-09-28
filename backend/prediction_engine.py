from models import MatchStatus, PredictionResult

class HeuristicPredictionEngine:
    def predict(self, match):
        if match is None:
            return PredictionResult(150, 50.0, "Initial state")

        innings = match.current_innings
        overs_done = innings.overs_as_float
        total_balls = match.total_overs * 6
        balls_bowled = innings.total_legal_balls
        balls_remaining = total_balls - balls_bowled
        wickets_lost = innings.total_wickets
        wickets_in_hand = 10 - wickets_lost
        crr = innings.current_run_rate

        if match.status == MatchStatus.FIRST_INNINGS:
            if balls_bowled == 0:
                return PredictionResult(160, 50.0, "1st Innings: Match start - 50/50 win chance")

            # Project score based on CRR & wickets in hand acceleration multiplier
            accel = 0.7 + (wickets_in_hand / 10.0) * 0.5
            projected_remaining_runs = (balls_remaining / 6.0) * max(crr, 7.5) * accel
            projected_score = int(round(innings.total_runs + projected_remaining_runs))

            # Base win probability on projected score relative to 160 benchmark
            win_prob = 50.0 + ((projected_score - 160) * 0.35)
            win_prob = max(10.0, min(90.0, win_prob))

            explanation = (f"Projected {projected_score} (CRR {crr:.1f}, {wickets_in_hand} wkts in hand, "
                           f"Accel {accel:.2f}x)")
            return PredictionResult(projected_score, win_prob, explanation)

        elif match.status == MatchStatus.SECOND_INNINGS:
            target = match.target_runs
            runs_needed = target - innings.total_runs

            if runs_needed <= 0:
                return PredictionResult(innings.total_runs, 100.0, f"{match.team2_name} achieved target!")

            if balls_remaining <= 0 or wickets_in_hand <= 0:
                return PredictionResult(innings.total_runs, 0.0, f"{match.team1_name} defended target successfully!")

            rrr = innings.required_run_rate

            # Win probability based on RRR vs CRR and wickets in hand
            diff = crr - rrr
            base_prob = 50.0 + (diff * 5.0) + ((wickets_in_hand - 5) * 4.0)
            win_prob = max(1.0, min(99.0, base_prob))

            projected_score = int(round(innings.total_runs + (balls_remaining / 6.0) * max(crr, 6.0)))
            explanation = (f"Need {runs_needed} off {balls_remaining}b (RRR {rrr:.1f}, CRR {crr:.1f}, "
                           f"{wickets_in_hand} wkts in hand)")
            return PredictionResult(projected_score, win_prob, explanation)

        else:
            is_team1_winner = match.winner_name == match.team1_name
            win_prob = 0.0 if is_team1_winner else 100.0
            return PredictionResult(innings.total_runs, win_prob, match.result_summary)
