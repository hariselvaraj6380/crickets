class PlayerState {
  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;
  final bool isOut;
  final String dismissalInfo;

  PlayerState({
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
    this.isOut = false,
    this.dismissalInfo = '',
  });

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    return PlayerState(
      name: json['name'] ?? '',
      runs: (json['runs'] as num?)?.toInt() ?? 0,
      balls: (json['balls'] as num?)?.toInt() ?? 0,
      fours: (json['fours'] as num?)?.toInt() ?? 0,
      sixes: (json['sixes'] as num?)?.toInt() ?? 0,
      strikeRate: (json['strikeRate'] as num?)?.toDouble() ?? 0.0,
      isOut: json['isOut'] ?? false,
      dismissalInfo: json['dismissalInfo'] ?? '',
    );
  }
}

class BowlerState {
  final String name;
  final String overs;
  final int runsConceded;
  final int wickets;
  final double economy;

  BowlerState({
    required this.name,
    required this.overs,
    required this.runsConceded,
    required this.wickets,
    required this.economy,
  });

  factory BowlerState.fromJson(Map<String, dynamic> json) {
    return BowlerState(
      name: json['name'] ?? '',
      overs: json['overs']?.toString() ?? '0.0',
      runsConceded: (json['runsConceded'] as num?)?.toInt() ?? 0,
      wickets: (json['wickets'] as num?)?.toInt() ?? 0,
      economy: (json['economy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BallState {
  final int ballId;
  final int overNumber;
  final int ballInOver;
  final String displayLabel;
  final String commentary;
  final int runsOffBat;
  final bool isWicket;

  BallState({
    required this.ballId,
    required this.overNumber,
    required this.ballInOver,
    required this.displayLabel,
    required this.commentary,
    required this.runsOffBat,
    required this.isWicket,
  });

  factory BallState.fromJson(Map<String, dynamic> json) {
    return BallState(
      ballId: (json['ballId'] as num?)?.toInt() ?? 0,
      overNumber: (json['overNumber'] as num?)?.toInt() ?? 0,
      ballInOver: (json['ballInOver'] as num?)?.toInt() ?? 0,
      displayLabel: json['displayLabel'] ?? '0',
      commentary: json['commentary'] ?? '',
      runsOffBat: (json['runsOffBat'] as num?)?.toInt() ?? 0,
      isWicket: json['isWicket'] ?? false,
    );
  }

  // Visualization helper properties
  double get estimatedSpeedKmh {
    // Generate deterministic realistic delivery speed based on ballId
    final base = (ballId * 7) % 25;
    if (isWicket) return 144.5;
    if (runsOffBat == 6) return 138.2;
    if (runsOffBat == 4) return 141.0;
    return 132.0 + base;
  }

  String get shotType {
    if (isWicket) return 'Edged & Caught / Bowled';
    switch (runsOffBat) {
      case 6:
        return (ballId % 2 == 0) ? 'Lofted Straight Drive (6)' : 'Pull Shot over Midwicket (6)';
      case 4:
        return (ballId % 2 == 0) ? 'Glorious Cover Drive (4)' : 'Slanted Square Cut (4)';
      case 3:
      case 2:
        return 'Pushed into Deep Gap (${runsOffBat})';
      case 1:
        return 'Tucked for Single (1)';
      default:
        return 'Defensive Block / Dot Ball';
    }
  }

  String get pitchLengthCategory {
    if (isWicket) return 'Yorker / Full Length';
    if (runsOffBat == 6) return 'Slot / Short Pitch';
    if (runsOffBat == 4) return 'Full Pitch';
    return 'Good Length';
  }

  // Shot angle relative to pitch centerline (in radians: 0 = straight drive, -pi/2 = offside cut, +pi/2 = legside pull)
  double get shotAngleRadians {
    if (isWicket) return 0.2;
    switch (runsOffBat) {
      case 6:
        return (ballId % 2 == 0) ? -0.15 : 1.25; // Straight or Leg side
      case 4:
        return (ballId % 2 == 0) ? -1.15 : 0.85; // Cover drive or Fine leg
      case 2:
      case 3:
        return (ballId % 2 == 0) ? -0.7 : 0.6;
      case 1:
        return 0.4;
      default:
        return 0.05;
    }
  }
}

class PredictionState {
  final String favoredTeam;
  final double winProbabilityTeam1;
  final double winProbabilityTeam2;
  final int projectedScore;
  final String explanation;

  PredictionState({
    required this.favoredTeam,
    required this.winProbabilityTeam1,
    required this.winProbabilityTeam2,
    required this.projectedScore,
    required this.explanation,
  });

  factory PredictionState.fromJson(Map<String, dynamic> json) {
    return PredictionState(
      favoredTeam: json['favoredTeam'] ?? '',
      winProbabilityTeam1: (json['winProbabilityTeam1'] as num?)?.toDouble() ?? 50.0,
      winProbabilityTeam2: (json['winProbabilityTeam2'] as num?)?.toDouble() ?? 50.0,
      projectedScore: (json['projectedScore'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

class MatchState {
  final int matchId;
  final String team1;
  final String team2;
  final int totalOvers;
  final String status;
  final int targetRuns;
  final String winnerName;
  final String resultSummary;
  final int currentInningsNumber;
  final String battingTeam;
  final String bowlingTeam;
  final int totalRuns;
  final int wickets;
  final int legalBalls;
  final String oversFormatted;
  final double currentRunRate;
  final double requiredRunRate;
  final bool isSimulating;
  final double speedMultiplier;
  final PlayerState? striker;
  final PlayerState? nonStriker;
  final BowlerState? bowler;
  final PredictionState prediction;
  final List<BallState> recentBalls;

  MatchState({
    required this.matchId,
    required this.team1,
    required this.team2,
    required this.totalOvers,
    required this.status,
    required this.targetRuns,
    required this.winnerName,
    required this.resultSummary,
    required this.currentInningsNumber,
    required this.battingTeam,
    required this.bowlingTeam,
    required this.totalRuns,
    required this.wickets,
    required this.legalBalls,
    required this.oversFormatted,
    required this.currentRunRate,
    required this.requiredRunRate,
    required this.isSimulating,
    required this.speedMultiplier,
    this.striker,
    this.nonStriker,
    this.bowler,
    required this.prediction,
    required this.recentBalls,
  });

  factory MatchState.fromJson(Map<String, dynamic> json) {
    List<BallState> balls = [];
    if (json['recentBalls'] != null) {
      balls = (json['recentBalls'] as List)
          .map((item) => BallState.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return MatchState(
      matchId: (json['matchId'] as num?)?.toInt() ?? 0,
      team1: json['team1'] ?? 'India',
      team2: json['team2'] ?? 'Australia',
      totalOvers: (json['totalOvers'] as num?)?.toInt() ?? 20,
      status: json['status'] ?? 'FIRST_INNINGS',
      targetRuns: (json['targetRuns'] as num?)?.toInt() ?? 0,
      winnerName: json['winnerName'] ?? '',
      resultSummary: json['resultSummary'] ?? '',
      currentInningsNumber: (json['currentInningsNumber'] as num?)?.toInt() ?? 1,
      battingTeam: json['battingTeam'] ?? 'India',
      bowlingTeam: json['bowlingTeam'] ?? 'Australia',
      totalRuns: (json['totalRuns'] as num?)?.toInt() ?? 0,
      wickets: (json['wickets'] as num?)?.toInt() ?? 0,
      legalBalls: (json['legalBalls'] as num?)?.toInt() ?? 0,
      oversFormatted: json['oversFormatted']?.toString() ?? '0.0',
      currentRunRate: (json['currentRunRate'] as num?)?.toDouble() ?? 0.0,
      requiredRunRate: (json['requiredRunRate'] as num?)?.toDouble() ?? 0.0,
      isSimulating: json['isSimulating'] ?? false,
      speedMultiplier: (json['speedMultiplier'] as num?)?.toDouble() ?? 1.0,
      striker: json['striker'] != null ? PlayerState.fromJson(json['striker']) : null,
      nonStriker: json['nonStriker'] != null ? PlayerState.fromJson(json['nonStriker']) : null,
      bowler: json['bowler'] != null ? BowlerState.fromJson(json['bowler']) : null,
      prediction: json['prediction'] != null
          ? PredictionState.fromJson(json['prediction'])
          : PredictionState(favoredTeam: '', winProbabilityTeam1: 50, winProbabilityTeam2: 50, projectedScore: 150, explanation: ''),
      recentBalls: balls,
    );
  }
}
