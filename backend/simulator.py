import random
import threading
import time
from models import (
    Match, Ball, ExtraType, WicketType, WicketInfo, MatchStatus
)
from prediction_engine import HeuristicPredictionEngine
from database import save_ball_event

INDIA_PLAYERS = [
    "Rohit Sharma", "Yashasvi Jaiswal", "Virat Kohli", "Suryakumar Yadav",
    "Rishabh Pant", "Hardik Pandya", "Axar Patel", "Ravindra Jadeja",
    "Kuldeep Yadav", "Jasprit Bumrah", "Mohammed Siraj"
]

AUSTRALIA_PLAYERS = [
    "Travis Head", "David Warner", "Mitchell Marsh", "Glenn Maxwell", "Marcus Stoinis",
    "Tim David", "Matthew Wade", "Pat Cummins", "Mitchell Starc", "Adam Zampa", "Josh Hazlewood"
]


class MatchSimulator:
    def __init__(self):
        self.lock = threading.RLock()
        self.prediction_engine = HeuristicPredictionEngine()
        self.match = None
        self.is_running = False
        self.speed_multiplier = 1.0
        self.sim_thread = None
        self.current_bowler_index = 7
        self.reset_new_match()

    def reset_new_match(self):
        with self.lock:
            self.is_running = False
            self.match = Match("India", "Australia", 20)
            self.match.first_innings.setup_players(INDIA_PLAYERS, AUSTRALIA_PLAYERS)
            self.match.second_innings.setup_players(AUSTRALIA_PLAYERS, INDIA_PLAYERS)
            self.current_bowler_index = 7

    def start(self):
        with self.lock:
            if self.match.status == MatchStatus.COMPLETED:
                self.reset_new_match()
            if not self.is_running:
                self.is_running = True
                self.sim_thread = threading.Thread(target=self._run_loop, daemon=True)
                self.sim_thread.start()

    def pause(self):
        with self.lock:
            self.is_running = False

    def stop(self):
        with self.lock:
            self.is_running = False

    def set_speed(self, multiplier):
        with self.lock:
            self.speed_multiplier = max(0.2, min(10.0, float(multiplier)))

    def _run_loop(self):
        while self.is_running:
            should_continue = False
            with self.lock:
                if self.is_running and self.match.status != MatchStatus.COMPLETED:
                    should_continue = True

            if not should_continue:
                self.is_running = False
                break

            self.step_single_ball()

            sleep_time = max(0.1, 1.5 / self.speed_multiplier)
            time.sleep(sleep_time)

    def step_single_ball(self):
        with self.lock:
            if self.match.status != MatchStatus.COMPLETED:
                self._generate_next_ball()

    def inject_custom_ball(self, runs=0, extra_type_str="NONE", wicket_type_str="NONE"):
        with self.lock:
            if self.match.status == MatchStatus.COMPLETED:
                return

            innings = self.match.current_innings
            striker = innings.current_striker
            non_striker = innings.current_non_striker
            bowler = innings.current_bowler

            if not striker or not bowler or not non_striker:
                return

            over_number = innings.total_legal_balls // 6
            ball_in_over = (innings.total_legal_balls % 6) + 1

            extra_type = ExtraType.NONE
            if extra_type_str == "WIDE":
                extra_type = ExtraType.WIDE
            elif extra_type_str == "NO_BALL":
                extra_type = ExtraType.NO_BALL
            elif extra_type_str == "BYE":
                extra_type = ExtraType.BYE
            elif extra_type_str == "LEG_BYE":
                extra_type = ExtraType.LEG_BYE

            wicket_type = WicketType.NONE
            if wicket_type_str and wicket_type_str != "NONE":
                try:
                    wicket_type = WicketType[wicket_type_str.upper()]
                except KeyError:
                    wicket_type = WicketType.BOWLED

            wicket_info = WicketInfo(wicket_type, striker.name) if wicket_type != WicketType.NONE else WicketInfo()
            commentary = self._build_commentary(striker.name, bowler.name, runs, extra_type, wicket_type)

            ball = Ball(
                self.match.id,
                innings.innings_number,
                over_number,
                ball_in_over,
                bowler.name,
                striker.name,
                non_striker.name,
                runs,
                extra_type,
                1 if extra_type != ExtraType.NONE else 0,
                wicket_info,
                commentary
            )

            innings.record_ball(ball)
            self.match.update_match_state()

            prediction = self.prediction_engine.predict(self.match)
            save_ball_event(ball, prediction)

    def _generate_next_ball(self):
        innings = self.match.current_innings

        # Rotate bowler at over boundary
        if (innings.total_legal_balls > 0 and innings.total_legal_balls % 6 == 0 and
            (not innings.recorded_balls or innings.recorded_balls[-1].is_legal_ball())):

            bowling_team_list = AUSTRALIA_PLAYERS if innings.innings_number == 1 else INDIA_PLAYERS
            self.current_bowler_index = 5 + random.randint(0, len(bowling_team_list) - 6)
            next_bowler_name = bowling_team_list[self.current_bowler_index]
            innings.current_bowler = innings.get_or_create_player(next_bowler_name, innings.bowling_team)

        striker = innings.current_striker
        non_striker = innings.current_non_striker
        bowler = innings.current_bowler

        if not striker or not bowler or not non_striker:
            self.is_running = False
            return

        over_number = innings.total_legal_balls // 6
        ball_in_over = (innings.total_legal_balls % 6) + 1

        # Outcome distribution weighted roll
        roll = random.uniform(0, 100)
        runs = 0
        extra_type = ExtraType.NONE
        extra_runs = 0
        wicket_type = WicketType.NONE

        if roll < 32.0:
            runs = 0
        elif roll < 62.0:
            runs = 1
        elif roll < 74.0:
            runs = 2
        elif roll < 77.0:
            runs = 3
        elif roll < 87.0:
            runs = 4
        elif roll < 93.0:
            runs = 6
        elif roll < 97.0:
            w_list = [WicketType.BOWLED, WicketType.CAUGHT, WicketType.LBW, WicketType.RUN_OUT, WicketType.STUMPED]
            wicket_type = random.choice(w_list)
        else:
            extra_type = random.choice([ExtraType.WIDE, ExtraType.NO_BALL])
            extra_runs = 1 if random.random() < 0.2 else 0

        wicket_info = WicketInfo(wicket_type, striker.name) if wicket_type != WicketType.NONE else WicketInfo()
        commentary = self._build_commentary(striker.name, bowler.name, runs, extra_type, wicket_type)

        ball = Ball(
            self.match.id,
            innings.innings_number,
            over_number,
            ball_in_over,
            bowler.name,
            striker.name,
            non_striker.name,
            runs,
            extra_type,
            extra_runs,
            wicket_info,
            commentary
        )

        innings.record_ball(ball)
        self.match.update_match_state()

        prediction = self.prediction_engine.predict(self.match)
        try:
            save_ball_event(ball, prediction)
        except Exception:
            pass

    def _build_commentary(self, striker, bowler, runs, extra, wicket):
        if wicket.is_wicket():
            return f"OUT! {bowler} strikes! {striker} is {wicket.display_name()}!"
        if extra == ExtraType.WIDE:
            return f"Wide ball! {bowler} strays down the leg side."
        if extra == ExtraType.NO_BALL:
            return f"No Ball! {bowler} oversteps the line."
        if runs == 4:
            return f"FOUR! Cracking shot by {striker} through cover off {bowler}!"
        if runs == 6:
            return f"SIX! Huge hit into the stands by {striker}!"
        if runs == 0:
            return f"Dot ball. Good tight line by {bowler} to {striker}."
        return f"{runs} run{'s' if runs > 1 else ''} to {striker}."
