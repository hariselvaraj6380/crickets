import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/match_state.dart';
import 'services/api_service.dart';
import 'widgets/batting_bowling_video_display.dart';
import 'widgets/commentary_stream.dart';
import 'widgets/current_players_card.dart';
import 'widgets/recent_balls_strip.dart';
import 'widgets/scorecard_dialog.dart';
import 'widgets/scoreboard_header.dart';
import 'widgets/simulation_controls.dart';
import 'widgets/win_prediction_widget.dart';

void main() {
  runApp(const CricketLiveScoreboardApp());
}

class CricketLiveScoreboardApp extends StatelessWidget {
  const CricketLiveScoreboardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cricket Live Scoreboard & AI Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFFF59E0B),
          surface: Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  MatchState? _matchState;
  Timer? _pollingTimer;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 800), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    final state = await _apiService.fetchMatchStatus();
    if (mounted) {
      setState(() {
        _matchState = state;
        _isConnected = state != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.sports_cricket_rounded, color: Color(0xFF38BDF8), size: 24),
            const SizedBox(width: 10),
            Text(
              'CRICKET LIVE SCOREBOARD',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? const Color(0xFF10B981) : Colors.red,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnected ? 'API CONNECTED' : 'DISCONNECTED',
                  style: GoogleFonts.inter(
                    color: _isConnected ? const Color(0xFF10B981) : Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _matchState == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF38BDF8)),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting to Java REST API Server on port 8080...',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      // Scoreboard Header Card
                      ScoreboardHeader(
                        matchState: _matchState!,
                        onOpenScorecard: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => ScorecardDialog(apiService: _apiService),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Simulation Controls Bar
                      SimulationControls(
                        matchState: _matchState!,
                        onPlay: () async {
                          await _apiService.playSimulation();
                          _fetchStatus();
                        },
                        onPause: () async {
                          await _apiService.pauseSimulation();
                          _fetchStatus();
                        },
                        onStep: () async {
                          await _apiService.stepSimulation();
                          _fetchStatus();
                        },
                        onReset: () async {
                          await _apiService.resetSimulation();
                          _fetchStatus();
                        },
                        onSpeedChanged: (speed) async {
                          await _apiService.setSpeed(speed);
                          _fetchStatus();
                        },
                        onInjectBall: (runs, extra, wicket) async {
                          await _apiService.injectCustomBall(runs, extra, wicket);
                          _fetchStatus();
                        },
                      ),

                      const SizedBox(height: 16),

                      // Batting & Bowling Video & Pitch Simulation Display
                      BattingBowlingVideoDisplay(matchState: _matchState!),

                      const SizedBox(height: 16),

                      // Win Prediction Widget
                      WinPredictionWidget(matchState: _matchState!),

                      const SizedBox(height: 16),

                      // Current Players Card (Striker, Non-Striker, Bowler)
                      CurrentPlayersCard(matchState: _matchState!),

                      const SizedBox(height: 16),

                      // Recent Balls Delivery Strip
                      RecentBallsStrip(balls: _matchState!.recentBalls),

                      const SizedBox(height: 16),

                      // Ball-by-Ball Live Commentary Stream
                      CommentaryStream(balls: _matchState!.recentBalls),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
