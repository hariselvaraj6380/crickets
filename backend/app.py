import logging
from flask import Flask, jsonify, request
from flask_cors import CORS

from database import init_db
from simulator import MatchSimulator

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

init_db()
simulator = MatchSimulator()


@app.route('/api/match/status', methods=['GET', 'OPTIONS'])
def get_status():
    if request.method == 'OPTIONS':
        return '', 204

    match = simulator.match
    if not match:
        return jsonify({'error': 'No active match'}), 404

    curr_inn = match.current_innings
    pred = simulator.prediction_engine.predict(match)

    striker_data = None
    if curr_inn.current_striker:
        s = curr_inn.current_striker
        striker_data = {
            'name': s.name,
            'runs': s.runs_scored,
            'balls': s.balls_faced,
            'fours': s.fours,
            'sixes': s.sixes,
            'strikeRate': round(s.strike_rate, 2),
        }

    non_striker_data = None
    if curr_inn.current_non_striker:
        ns = curr_inn.current_non_striker
        non_striker_data = {
            'name': ns.name,
            'runs': ns.runs_scored,
            'balls': ns.balls_faced,
            'fours': ns.fours,
            'sixes': ns.sixes,
            'strikeRate': round(ns.strike_rate, 2),
        }

    bowler_data = None
    if curr_inn.current_bowler:
        b = curr_inn.current_bowler
        bowler_data = {
            'name': b.name,
            'overs': b.bowling_overs_string,
            'runsConceded': b.bowling_runs_conceded,
            'wickets': b.bowling_wickets,
            'economy': round(b.economy_rate, 2),
        }

    favored_team = curr_inn.batting_team if pred.win_probability_batting >= 50.0 else curr_inn.bowling_team

    recent_balls_data = []
    for b in curr_inn.recorded_balls[-14:]:
        recent_balls_data.append({
            'ballId': b.id or 0,
            'overNumber': b.over_number,
            'ballInOver': b.ball_in_over,
            'displayLabel': b.get_chip_text(),
            'commentary': b.commentary,
            'runsOffBat': b.runs_off_bat,
            'isWicket': b.wicket_info.is_wicket(),
        })

    return jsonify({
        'matchId': match.id,
        'team1': match.team1_name,
        'team2': match.team2_name,
        'totalOvers': match.total_overs,
        'status': match.status.value,
        'targetRuns': match.target_runs,
        'winnerName': match.winner_name,
        'resultSummary': match.result_summary,
        'currentInningsNumber': curr_inn.innings_number,
        'battingTeam': curr_inn.batting_team,
        'bowlingTeam': curr_inn.bowling_team,
        'totalRuns': curr_inn.total_runs,
        'wickets': curr_inn.total_wickets,
        'legalBalls': curr_inn.total_legal_balls,
        'oversFormatted': curr_inn.overs_formatted,
        'currentRunRate': round(curr_inn.current_run_rate, 2),
        'requiredRunRate': round(curr_inn.required_run_rate, 2),
        'isSimulating': simulator.is_running,
        'speedMultiplier': simulator.speed_multiplier,
        'striker': striker_data,
        'nonStriker': non_striker_data,
        'bowler': bowler_data,
        'prediction': {
            'favoredTeam': favored_team,
            'winProbabilityTeam1': round(pred.win_probability_batting, 1),
            'winProbabilityTeam2': round(pred.win_probability_bowling, 1),
            'projectedScore': pred.projected_score,
            'explanation': pred.explanation,
        },
        'recentBalls': recent_balls_data,
    })


@app.route('/api/match/scorecard', methods=['GET', 'OPTIONS'])
def get_scorecard():
    if request.method == 'OPTIONS':
        return '', 204

    match = simulator.match
    if not match:
        return jsonify({'error': 'No active match'}), 404

    innings_list = []
    for inn in [match.first_innings, match.second_innings]:
        batters = []
        for p in inn.players_map.values():
            is_current = (inn.current_striker and p.name == inn.current_striker.name) or \
                         (inn.current_non_striker and p.name == inn.current_non_striker.name)
            if p.team_name == inn.batting_team and (p.balls_faced > 0 or p.is_out or is_current):
                batters.append({
                    'name': p.name,
                    'runs': p.runs_scored,
                    'balls': p.balls_faced,
                    'fours': p.fours,
                    'sixes': p.sixes,
                    'strikeRate': round(p.strike_rate, 2),
                    'isOut': p.is_out,
                    'dismissalInfo': p.dismissal_info,
                })

        bowlers = []
        for p in inn.players_map.values():
            if p.team_name == inn.bowling_team and p.bowling_legal_balls > 0:
                bowlers.append({
                    'name': p.name,
                    'overs': p.bowling_overs_string,
                    'runsConceded': p.bowling_runs_conceded,
                    'wickets': p.bowling_wickets,
                    'economy': round(p.economy_rate, 2),
                })

        innings_list.append({
            'inningsNumber': inn.innings_number,
            'battingTeam': inn.batting_team,
            'bowlingTeam': inn.bowling_team,
            'totalRuns': inn.total_runs,
            'wickets': inn.total_wickets,
            'oversFormatted': inn.overs_formatted,
            'batters': batters,
            'bowlers': bowlers,
        })

    return jsonify({
        'matchId': match.id,
        'status': match.status.value,
        'innings': innings_list,
    })


@app.route('/api/match/sim/play', methods=['POST', 'OPTIONS'])
def sim_play():
    if request.method == 'OPTIONS':
        return '', 204

    simulator.start()
    return jsonify({'message': 'Simulation started', 'isSimulating': simulator.is_running})


@app.route('/api/match/sim/pause', methods=['POST', 'OPTIONS'])
def sim_pause():
    if request.method == 'OPTIONS':
        return '', 204

    simulator.pause()
    return jsonify({'message': 'Simulation paused', 'isSimulating': simulator.is_running})


@app.route('/api/match/sim/step', methods=['POST', 'OPTIONS'])
def sim_step():
    if request.method == 'OPTIONS':
        return '', 204

    simulator.step_single_ball()
    return get_status()


@app.route('/api/match/sim/reset', methods=['POST', 'OPTIONS'])
def sim_reset():
    if request.method == 'OPTIONS':
        return '', 204

    simulator.reset_new_match()
    return get_status()


@app.route('/api/match/sim/speed', methods=['POST', 'OPTIONS'])
def sim_speed():
    if request.method == 'OPTIONS':
        return '', 204

    data = request.get_json(silent=True) or {}
    multiplier = data.get('multiplier', 1.0)
    simulator.set_speed(multiplier)
    return jsonify({'speedMultiplier': simulator.speed_multiplier})


@app.route('/api/match/sim/ball', methods=['POST', 'OPTIONS'])
def sim_ball():
    if request.method == 'OPTIONS':
        return '', 204

    data = request.get_json(silent=True) or {}
    runs = int(data.get('runs', 0))
    extra_type = data.get('extraType', 'NONE')
    wicket_type = data.get('wicketType', 'NONE')

    simulator.inject_custom_ball(runs, extra_type, wicket_type)
    return get_status()


if __name__ == '__main__':
    logger.info("Starting Cricket Python Flask REST Server on port 8080...")
    app.run(host='0.0.0.0', port=8080, debug=False, threaded=True)
