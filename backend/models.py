from enum import Enum
import math
import time

class ExtraType(Enum):
    NONE = 'NONE'
    WIDE = 'WIDE'
    NO_BALL = 'NO_BALL'
    BYE = 'BYE'
    LEG_BYE = 'LEG_BYE'

    def counts_as_legal_ball(self):
        return self not in (ExtraType.WIDE, ExtraType.NO_BALL)


class WicketType(Enum):
    NONE = 'NONE'
    BOWLED = 'BOWLED'
    CAUGHT = 'CAUGHT'
    LBW = 'LBW'
    RUN_OUT = 'RUN_OUT'
    STUMPED = 'STUMPED'

    def is_wicket(self):
        return self != WicketType.NONE

    def display_name(self):
        names = {
            WicketType.BOWLED: 'Bowled',
            WicketType.CAUGHT: 'Caught',
            WicketType.LBW: 'LBW',
            WicketType.RUN_OUT: 'Run Out',
            WicketType.STUMPED: 'Stumped',
        }
        return names.get(self, 'Out')


class MatchStatus(Enum):
    FIRST_INNINGS = 'FIRST_INNINGS'
    SECOND_INNINGS = 'SECOND_INNINGS'
    COMPLETED = 'COMPLETED'


class WicketInfo:
    def __init__(self, wicket_type=WicketType.NONE, dismissed_player=None):
        self.wicket_type = wicket_type
        self.dismissed_player = dismissed_player

    def is_wicket(self):
        return self.wicket_type != WicketType.NONE


class Ball:
    def __init__(self, match_id, innings_number, over_number, ball_in_over,
                 bowler_name, batsman_name, non_striker_name,
                 runs_off_bat=0, extra_type=ExtraType.NONE, extra_runs=0,
                 wicket_info=None, commentary=''):
        self.id = None
        self.match_id = match_id
        self.innings_number = innings_number
        self.over_number = over_number
        self.ball_in_over = ball_in_over
        self.legal_ball_number = 0
        self.bowler_name = bowler_name
        self.batsman_name = batsman_name
        self.non_striker_name = non_striker_name
        self.runs_off_bat = runs_off_bat
        self.extra_type = extra_type if isinstance(extra_type, ExtraType) else ExtraType.NONE
        self.extra_runs = extra_runs
        self.wicket_info = wicket_info or WicketInfo()
        self.commentary = commentary
        self.recorded_at = time.time()

    def get_total_runs(self):
        total = self.runs_off_bat + self.extra_runs
        if self.extra_type in (ExtraType.WIDE, ExtraType.NO_BALL):
            total += 1
        return total

    def is_legal_ball(self):
        return self.extra_type.counts_as_legal_ball()

    def get_chip_text(self):
        if self.wicket_info.is_wicket():
            return 'W'
        if self.extra_type == ExtraType.WIDE:
            return f"{self.extra_runs + 1}Wd" if self.extra_runs > 0 else "Wd"
        if self.extra_type == ExtraType.NO_BALL:
            return f"{self.runs_off_bat + 1}Nb" if self.runs_off_bat > 0 else "Nb"
        if self.extra_type == ExtraType.BYE:
            return f"{self.extra_runs}B"
        if self.extra_type == ExtraType.LEG_BYE:
            return f"{self.extra_runs}Lb"
        return str(self.runs_off_bat)


class Player:
    def __init__(self, name, team_name):
        self.id = None
        self.name = name
        self.team_name = team_name
        self.runs_scored = 0
        self.balls_faced = 0
        self.fours = 0
        self.sixes = 0
        self.is_out = False
        self.dismissal_info = ''
        self.bowling_legal_balls = 0
        self.bowling_runs_conceded = 0
        self.bowling_wickets = 0

    @property
    def strike_rate(self):
        if self.balls_faced == 0:
            return 0.0
        return (self.runs_scored * 100.0) / self.balls_faced

    def record_batting(self, runs, counts_as_ball_faced):
        self.runs_scored += runs
        if counts_as_ball_faced:
            self.balls_faced += 1
        if runs == 4:
            self.fours += 1
        if runs == 6:
            self.sixes += 1

    @property
    def bowling_overs_string(self):
        overs = self.bowling_legal_balls // 6
        balls = self.bowling_legal_balls % 6
        return f"{overs}.{balls}"

    @property
    def economy_rate(self):
        overs = self.bowling_legal_balls / 6.0
        if overs == 0:
            return 0.0
        return self.bowling_runs_conceded / overs

    def record_bowling(self, runs, is_legal_ball, is_wicket):
        self.bowling_runs_conceded += runs
        if is_legal_ball:
            self.bowling_legal_balls += 1
        if is_wicket:
            self.bowling_wickets += 1


class Innings:
    def __init__(self, match_id, innings_number, batting_team, bowling_team, max_overs=20):
        self.id = None
        self.match_id = match_id
        self.innings_number = innings_number
        self.batting_team = batting_team
        self.bowling_team = bowling_team
        self.max_overs = max_overs

        self.total_runs = 0
        self.total_wickets = 0
        self.total_legal_balls = 0
        self.target_runs = 0
        self.is_completed = False

        self.recorded_balls = []
        self.players_map = {}  # name -> Player
        self.current_striker = None
        self.current_non_striker = None
        self.current_bowler = None
        self.batting_lineup = []
        self.next_batting_index = 0

    def setup_players(self, batting_players, bowling_players):
        for p_name in batting_players:
            p = Player(p_name, self.batting_team)
            self.players_map[p_name] = p
            self.batting_lineup.append(p_name)
        for p_name in bowling_players:
            p = Player(p_name, self.bowling_team)
            self.players_map[p_name] = p

        if len(self.batting_lineup) >= 2:
            self.current_striker = self.players_map[self.batting_lineup[0]]
            self.current_non_striker = self.players_map[self.batting_lineup[1]]
            self.next_batting_index = 2
        if bowling_players:
            self.current_bowler = self.players_map[bowling_players[0]]

    def get_or_create_player(self, name, team):
        if name not in self.players_map:
            self.players_map[name] = Player(name, team)
        return self.players_map[name]

    def swap_strike(self):
        self.current_striker, self.current_non_striker = self.current_non_striker, self.current_striker

    def record_ball(self, ball):
        if self.is_completed:
            return

        ball_total = ball.get_total_runs()
        self.total_runs += ball_total

        is_legal = ball.is_legal_ball()
        if is_legal:
            self.total_legal_balls += 1
            ball.legal_ball_number = self.total_legal_balls

        striker = self.get_or_create_player(ball.batsman_name, self.batting_team)
        bowler = self.get_or_create_player(ball.bowler_name, self.bowling_team)
        self.current_striker = striker
        self.current_bowler = bowler

        counts_as_ball_faced = (ball.extra_type != ExtraType.WIDE)
        striker.record_batting(ball.runs_off_bat, counts_as_ball_faced)

        bowling_runs = ball.runs_off_bat
        if ball.extra_type in (ExtraType.WIDE, ExtraType.NO_BALL):
            bowling_runs += 1 + ball.extra_runs

        is_wicket_for_bowler = (ball.wicket_info.is_wicket() and ball.wicket_info.wicket_type != WicketType.RUN_OUT)
        bowler.record_bowling(bowling_runs, is_legal, is_wicket_for_bowler)

        if ball.wicket_info.is_wicket():
            self.total_wickets += 1
            dismissed_name = ball.wicket_info.dismissed_player or striker.name
            dismissed_p = self.get_or_create_player(dismissed_name, self.batting_team)
            dismissed_p.is_out = True
            dismissed_p.dismissal_info = ball.wicket_info.wicket_type.display_name()

            if self.total_wickets < 10 and self.next_batting_index < len(self.batting_lineup):
                new_batter = self.players_map[self.batting_lineup[self.next_batting_index]]
                self.next_batting_index += 1
                if dismissed_p.name == striker.name:
                    self.current_striker = new_batter
                else:
                    self.current_non_striker = new_batter

        self.recorded_balls.append(ball)

        physical_runs = ball.runs_off_bat
        if ball.extra_type in (ExtraType.BYE, ExtraType.LEG_BYE):
            physical_runs = ball.extra_runs

        if physical_runs % 2 != 0:
            self.swap_strike()

        if is_legal and self.total_legal_balls > 0 and self.total_legal_balls % 6 == 0:
            self.swap_strike()

        if self.total_wickets >= 10 or self.total_legal_balls >= self.max_overs * 6:
            self.is_completed = True
        elif self.target_runs > 0 and self.total_runs >= self.target_runs:
            self.is_completed = True

    @property
    def overs_formatted(self):
        overs = self.total_legal_balls // 6
        balls = self.total_legal_balls % 6
        return f"{overs}.{balls}"

    @property
    def overs_as_float(self):
        overs = self.total_legal_balls // 6
        balls = self.total_legal_balls % 6
        return overs + (balls / 6.0)

    @property
    def current_run_rate(self):
        overs = self.overs_as_float
        if overs <= 0:
            return 0.0
        return self.total_runs / overs

    @property
    def required_run_rate(self):
        if self.target_runs <= 0 or self.innings_number != 2:
            return 0.0
        runs_needed = self.target_runs - self.total_runs
        if runs_needed <= 0:
            return 0.0
        remaining_balls = (self.max_overs * 6) - self.total_legal_balls
        if remaining_balls <= 0:
            return 99.9
        return runs_needed / (remaining_balls / 6.0)


class Match:
    def __init__(self, team1_name="India", team2_name="Australia", total_overs=20):
        self.id = 1
        self.team1_name = team1_name
        self.team2_name = team2_name
        self.total_overs = total_overs
        self.status = MatchStatus.FIRST_INNINGS
        self.target_runs = 0
        self.winner_name = ""
        self.result_summary = ""

        self.first_innings = Innings(self.id, 1, team1_name, team2_name, total_overs)
        self.second_innings = Innings(self.id, 2, team2_name, team1_name, total_overs)

    @property
    def current_innings(self):
        if self.status == MatchStatus.SECOND_INNINGS:
            return self.second_innings
        return self.first_innings

    def update_match_state(self):
        if self.status == MatchStatus.FIRST_INNINGS:
            if self.first_innings.is_completed:
                self.target_runs = self.first_innings.total_runs + 1
                self.second_innings.target_runs = self.target_runs
                self.status = MatchStatus.SECOND_INNINGS
        elif self.status == MatchStatus.SECOND_INNINGS:
            if self.second_innings.is_completed or self.second_innings.total_runs >= self.target_runs:
                self.status = MatchStatus.COMPLETED
                self._determine_winner()

    def _determine_winner(self):
        t1_runs = self.first_innings.total_runs
        t2_runs = self.second_innings.total_runs
        if t2_runs >= self.target_runs:
            self.winner_name = self.team2_name
            wkts_left = 10 - self.second_innings.total_wickets
            balls_left = (self.total_overs * 6) - self.second_innings.total_legal_balls
            self.result_summary = f"{self.team2_name} won by {wkts_left} wickets ({balls_left} balls remaining)"
        elif t2_runs < t1_runs and self.second_innings.is_completed:
            self.winner_name = self.team1_name
            margin = t1_runs - t2_runs
            self.result_summary = f"{self.team1_name} won by {margin} runs"
        elif t2_runs == t1_runs and self.second_innings.is_completed:
            self.winner_name = "Tie"
            self.result_summary = "Match Tied!"


class PredictionResult:
    def __init__(self, projected_score, win_probability_batting, explanation=""):
        self.projected_score = projected_score
        self.win_probability_batting = max(0.0, min(100.0, win_probability_batting))
        self.win_probability_bowling = 100.0 - self.win_probability_batting
        self.explanation = explanation
