import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/match_state.dart';
import 'realistic_cricket_assets.dart';

enum VideoDisplayMode { broadcastCam, hawkeye, pitchRadar, analytics }

class BattingBowlingVideoDisplay extends StatefulWidget {
  final MatchState matchState;

  const BattingBowlingVideoDisplay({Key? key, required this.matchState}) : super(key: key);

  @override
  State<BattingBowlingVideoDisplay> createState() => _BattingBowlingVideoDisplayState();
}

class _BattingBowlingVideoDisplayState extends State<BattingBowlingVideoDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  VideoDisplayMode _currentMode = VideoDisplayMode.broadcastCam;
  bool _isSlowMo = false;
  int _lastBallId = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _triggerBallAnimationIfNeeded();
  }

  @override
  void didUpdateWidget(covariant BattingBowlingVideoDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _triggerBallAnimationIfNeeded();
  }

  void _triggerBallAnimationIfNeeded() {
    final recent = widget.matchState.recentBalls;
    if (recent.isNotEmpty) {
      final latest = recent.first;
      if (latest.ballId != _lastBallId) {
        _lastBallId = latest.ballId;
        _animController.duration = Duration(milliseconds: _isSlowMo ? 3500 : 1800);
        _animController.forward(from: 0.0);
      }
    }
  }

  void _replayLastBall() {
    _animController.duration = Duration(milliseconds: _isSlowMo ? 3500 : 1800);
    _animController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentBalls = widget.matchState.recentBalls;
    final latestBall = recentBalls.isNotEmpty ? recentBalls.first : null;
    final striker = widget.matchState.striker;
    final bowler = widget.matchState.bowler;
    final isIndiaBatting = widget.matchState.battingTeam.toLowerCase().contains('ind');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withOpacity(0.1),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar & Mode Switcher
          _buildHeaderBar(),

          // Main Interactive Display Viewport
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 3D Stadium Background Image Layer
                  Positioned.fill(
                    child: Image.asset(
                      'assets/stadium.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(color: const Color(0xFF0D2818)),
                    ),
                  ),

                  // Stadium Vignette Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.transparent,
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Selected Display Canvas / View
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _buildModeView(latestBall, striker, bowler, isIndiaBatting),
                  ),

                  // Player Face Identity Spotlight Badges (Top Left & Top Right)
                  if (striker != null && bowler != null) _buildPlayerFaceSpotlight(striker, bowler, isIndiaBatting),

                  // Speed Radar Gun Overlay (Top Right Below Spotlight)
                  if (latestBall != null) _buildSpeedGunOverlay(latestBall),

                  // Ball Event Result Banner (Center Animated Banner)
                  if (latestBall != null) _buildEventResultBanner(latestBall),

                  // Bottom Controls Overlay
                  _buildBottomControlBar(latestBall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.videocam_rounded, color: Color(0xFF38BDF8), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ULTRA-HD REAL CRICKET BROADCAST',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Real Player Faces, Zing LED Bails & Hawkeye 3D Engine',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          // Camera View Selector Tabs
          Row(
            children: [
              _buildModeTab(VideoDisplayMode.broadcastCam, '🎥 Broadcast', Icons.tv_rounded),
              const SizedBox(width: 6),
              _buildModeTab(VideoDisplayMode.hawkeye, '🎯 Hawkeye', Icons.track_changes_rounded),
              const SizedBox(width: 6),
              _buildModeTab(VideoDisplayMode.pitchRadar, '🏏 Pitch Cam', Icons.sports_cricket_rounded),
              const SizedBox(width: 6),
              _buildModeTab(VideoDisplayMode.analytics, '📊 Telemetry', Icons.insights_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(VideoDisplayMode mode, String label, IconData icon) {
    final isSelected = _currentMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _currentMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: isSelected ? Colors.black : Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeView(BallState? latestBall, PlayerState? striker, BowlerState? bowler, bool isIndiaBatting) {
    switch (_currentMode) {
      case VideoDisplayMode.broadcastCam:
        return _buildBroadcastCamView(latestBall, striker, bowler, isIndiaBatting);
      case VideoDisplayMode.hawkeye:
        return _buildHawkeyeView(latestBall, striker, bowler);
      case VideoDisplayMode.pitchRadar:
        return _buildPitchRadarView(latestBall, striker, bowler);
      case VideoDisplayMode.analytics:
        return _buildTelemetryView(latestBall, striker, bowler);
    }
  }

  Widget _buildBroadcastCamView(BallState? ball, PlayerState? striker, BowlerState? bowler, bool isIndiaBatting) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          key: const ValueKey('broadcast_cam'),
          painter: BroadcastStadiumPainter(
            progress: _animController.value,
            ballState: ball,
            strikerName: striker?.name ?? 'Rohit Sharma',
            bowlerName: bowler?.name ?? 'Jasprit Bumrah',
            isIndiaBatting: isIndiaBatting,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildHawkeyeView(BallState? ball, PlayerState? striker, BowlerState? bowler) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          key: const ValueKey('hawkeye_cam'),
          painter: HawkeyeCameraPainter(
            progress: _animController.value,
            ballState: ball,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildPitchRadarView(BallState? ball, PlayerState? striker, BowlerState? bowler) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          key: const ValueKey('pitch_radar'),
          painter: PitchRadarPainter(
            progress: _animController.value,
            ballState: ball,
            strikerName: striker?.name ?? 'Batter',
            bowlerName: bowler?.name ?? 'Bowler',
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildTelemetryView(BallState? ball, PlayerState? striker, BowlerState? bowler) {
    final speed = ball?.estimatedSpeedKmh ?? 138.0;
    final shot = ball?.shotType ?? 'Defensive Shot';
    final length = ball?.pitchLengthCategory ?? 'Good Length';
    final runs = ball?.runsOffBat ?? 0;

    return Container(
      key: const ValueKey('telemetry'),
      color: const Color(0xFF0B132B).withOpacity(0.92),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2541).withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'BOWLING RELEASE METRICS',
                        style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatLine('Active Bowler', bowler?.name ?? 'Jasprit Bumrah'),
                  _buildStatLine('Release Speed', '${speed.toStringAsFixed(1)} km/h'),
                  _buildStatLine('Pitch Length', length),
                  _buildStatLine('Line', 'Outside Off-Stump'),
                  _buildStatLine('Seam / Spin Angle', '2.4° Inswing'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2541).withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_baseball_rounded, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'BATTING IMPACT & SHOT WHEEL',
                        style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatLine('Striker on Crease', striker?.name ?? 'Rohit Sharma'),
                  _buildStatLine('Shot Selection', shot),
                  _buildStatLine('Bat Exit Velocity', '${(speed * 0.9 + runs * 12).toStringAsFixed(1)} km/h'),
                  _buildStatLine('Impact Point', 'Middle of Bat'),
                  _buildStatLine('Runs Result', ball != null && ball.isWicket ? 'WICKET (OUT)' : '$runs Runs'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // Player Face Identity Spotlight Badge
  Widget _buildPlayerFaceSpotlight(PlayerState striker, BowlerState bowler, bool isIndiaBatting) {
    return Positioned(
      top: 14,
      left: 14,
      child: Row(
        children: [
          // Striker Identity Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isIndiaBatting ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CustomPaint(
                    painter: FaceBadgePainter(playerName: striker.name, isIndia: isIndiaBatting),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BATTER',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      striker.name,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Bowler Identity Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: !isIndiaBatting ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CustomPaint(
                    painter: FaceBadgePainter(playerName: bowler.name, isIndia: !isIndiaBatting),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BOWLER',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      bowler.name,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Speed Gun Overlay
  Widget _buildSpeedGunOverlay(BallState ball) {
    final speed = ball.estimatedSpeedKmh;

    return Positioned(
      top: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed_rounded, color: Color(0xFF38BDF8), size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SPEED RADAR',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${speed.toStringAsFixed(1)} km/h',
                  style: GoogleFonts.outfit(color: const Color(0xFF38BDF8), fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Dynamic Event Result Banner
  Widget _buildEventResultBanner(BallState ball) {
    if (_animController.value < 0.45) return const SizedBox.shrink();

    Color bgColor = Colors.blue.withOpacity(0.85);
    String title = '${ball.runsOffBat} RUNS';
    IconData icon = Icons.directions_run_rounded;

    if (ball.isWicket) {
      bgColor = const Color(0xFFEF4444).withOpacity(0.95);
      title = 'WICKET!';
      icon = Icons.error_outline_rounded;
    } else if (ball.runsOffBat == 6) {
      bgColor = const Color(0xFFF59E0B).withOpacity(0.95);
      title = 'MAXIMUM! 6 RUNS';
      icon = Icons.local_fire_department_rounded;
    } else if (ball.runsOffBat == 4) {
      bgColor = const Color(0xFF10B981).withOpacity(0.95);
      title = 'FOUR! 4 RUNS';
      icon = Icons.sports_cricket_rounded;
    } else if (ball.runsOffBat == 0) {
      bgColor = const Color(0xFF334155).withOpacity(0.85);
      title = 'DOT BALL';
      icon = Icons.shield_outlined;
    }

    return Positioned(
      top: 55,
      left: 14,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.45, 0.7)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 12, spreadRadius: 1),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom Control Bar
  Widget _buildBottomControlBar(BallState? ball) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                ball != null ? 'Shot: ${ball.shotType} • ${ball.commentary}' : 'Awaiting next delivery...',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),

            IconButton(
              onPressed: _replayLastBall,
              tooltip: 'Replay Last Ball Animation',
              icon: const Icon(Icons.replay_rounded, color: Color(0xFF38BDF8), size: 20),
            ),

            InkWell(
              onTap: () {
                setState(() {
                  _isSlowMo = !_isSlowMo;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isSlowMo ? const Color(0xFFF59E0B) : Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SLOW-MO',
                  style: GoogleFonts.outfit(
                    color: _isSlowMo ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Face Badge Painter Helper
class FaceBadgePainter extends CustomPainter {
  final String playerName;
  final bool isIndia;

  FaceBadgePainter({required this.playerName, required this.isIndia});

  @override
  void paint(Canvas canvas, Size size) {
    RealisticCricketAssets.drawCricketerFaceIdentity(
      canvas,
      Offset(size.width / 2, size.height / 2),
      playerName: playerName,
      isIndia: isIndia,
      size: size.width,
    );
  }

  @override
  bool shouldRepaint(covariant FaceBadgePainter oldDelegate) {
    return oldDelegate.playerName != playerName || oldDelegate.isIndia != isIndia;
  }
}

// ---------------------------------------------------------------------------
// 1. BROADCAST STADIUM PAINTER (3D Perspective + Real Player Face Identities)
// ---------------------------------------------------------------------------
class BroadcastStadiumPainter extends CustomPainter {
  final double progress;
  final BallState? ballState;
  final String strikerName;
  final String bowlerName;
  final bool isIndiaBatting;

  BroadcastStadiumPainter({
    required this.progress,
    required this.ballState,
    required this.strikerName,
    required this.bowlerName,
    required this.isIndiaBatting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pitch & Creases Perspective
    final pitchTopWidth = w * 0.16;
    final pitchBottomWidth = w * 0.36;
    final pitchTopY = h * 0.22;
    final pitchBottomY = h * 0.88;
    final centerX = w / 2;

    final pitchPath = Path()
      ..moveTo(centerX - pitchTopWidth / 2, pitchTopY)
      ..lineTo(centerX + pitchTopWidth / 2, pitchTopY)
      ..lineTo(centerX + pitchBottomWidth / 2, pitchBottomY)
      ..lineTo(centerX - pitchBottomWidth / 2, pitchBottomY)
      ..close();

    final pitchGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Color(0xFFD4A373), Color(0xFFC38E70)],
    );
    canvas.drawPath(pitchPath, Paint()..shader = pitchGradient.createShader(pitchPath.getBounds()));

    final linePaint = Paint()..color = Colors.white.withOpacity(0.9)..strokeWidth = 2.0;

    final topCreaseY = pitchTopY + (pitchBottomY - pitchTopY) * 0.08;
    canvas.drawLine(Offset(centerX - pitchTopWidth * 0.4, topCreaseY), Offset(centerX + pitchTopWidth * 0.4, topCreaseY), linePaint);

    final bottomCreaseY = pitchTopY + (pitchBottomY - pitchTopY) * 0.85;
    canvas.drawLine(Offset(centerX - pitchBottomWidth * 0.4, bottomCreaseY), Offset(centerX + pitchBottomWidth * 0.4, bottomCreaseY), linePaint);

    // Zing LED Stumps & Bails
    final isWicket = ballState?.isWicket ?? false;
    final isWicketAnimationHit = isWicket && progress >= 0.5;

    RealisticCricketAssets.drawZingStumps(canvas, Offset(centerX, topCreaseY), scale: 0.65, isWicketHit: false);
    RealisticCricketAssets.drawZingStumps(canvas, Offset(centerX, bottomCreaseY), scale: 1.05, isWicketHit: isWicketAnimationHit);

    // Realistic Bowler & Batter Avatars with face identity
    final bowlerY = topCreaseY - 14;
    final batterY = bottomCreaseY - 4;

    RealisticCricketAssets.drawRealisticBowler(
      canvas,
      Offset(centerX - 12, bowlerY),
      scale: 0.85,
      isIndia: !isIndiaBatting,
      armRotationProgress: progress < 0.4 ? (progress / 0.4) : 1.0,
      playerName: bowlerName,
    );

    double batAngle = -0.3;
    if (progress > 0.45 && ballState != null) {
      batAngle = ballState!.shotAngleRadians * 0.8 - 0.4;
    }

    RealisticCricketAssets.drawRealisticBatter(
      canvas,
      Offset(centerX, batterY),
      scale: 1.15,
      isIndia: isIndiaBatting,
      batAngle: batAngle,
      isStriker: true,
      playerName: strikerName,
    );

    RealisticCricketAssets.drawRealisticBatter(
      canvas,
      Offset(centerX + 24, bowlerY + 6),
      scale: 0.78,
      isIndia: isIndiaBatting,
      batAngle: 0.1,
      isStriker: false,
      playerName: 'Yashasvi Jaiswal',
    );

    // Fielders with face identity hats
    _drawFieldersWithFaceIdentity(canvas, size, !isIndiaBatting);

    // Ball Trajectory
    if (ballState != null) {
      final runs = ballState!.runsOffBat;
      final bounceY = pitchTopY + (pitchBottomY - pitchTopY) * 0.55;
      final bounceX = centerX + (ballState!.ballId % 3 - 1) * 8.0;

      Offset ballPos = Offset(centerX, topCreaseY);

      if (progress <= 0.4) {
        final t = progress / 0.4;
        ballPos = Offset.lerp(Offset(centerX, topCreaseY), Offset(bounceX, bounceY), t)!;
      } else if (progress <= 0.5) {
        final t = (progress - 0.4) / 0.1;
        ballPos = Offset.lerp(Offset(bounceX, bounceY), Offset(centerX, bottomCreaseY), t)!;
      } else {
        final t = (progress - 0.5) / 0.5;
        final shotAngle = ballState!.shotAngleRadians;
        double targetDist = runs == 6 ? w * 0.45 : (runs == 4 ? w * 0.38 : w * 0.2);
        if (isWicket) targetDist = 18.0;

        final targetX = centerX + math.sin(shotAngle) * targetDist;
        final targetY = bottomCreaseY - math.cos(shotAngle) * targetDist;

        ballPos = Offset.lerp(Offset(centerX, bottomCreaseY), Offset(targetX, targetY), t)!;

        canvas.drawLine(
          Offset(centerX, bottomCreaseY),
          ballPos,
          Paint()
            ..color = (runs == 6 ? const Color(0xFFF59E0B) : (runs == 4 ? const Color(0xFF10B981) : const Color(0xFF38BDF8))).withOpacity(0.6)
            ..strokeWidth = 2.5,
        );
      }

      if (progress >= 0.4) {
        canvas.drawCircle(Offset(bounceX, bounceY), 4.5, Paint()..color = const Color(0xFFF59E0B));
        canvas.drawCircle(Offset(bounceX, bounceY), 8.5, Paint()..color = const Color(0xFFF59E0B).withOpacity(0.3));
      }

      canvas.drawCircle(ballPos, 7, Paint()..color = const Color(0xFFEF4444).withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(ballPos, 4, Paint()..color = const Color(0xFFDC2626));
    }
  }

  void _drawFieldersWithFaceIdentity(Canvas canvas, Size size, bool isIndiaBowling) {
    final w = size.width;
    final h = size.height;

    final fielders = [
      {'pos': Offset(w * 0.38, h * 0.45), 'name': 'Travis Head'},
      {'pos': Offset(w * 0.25, h * 0.65), 'name': 'Glenn Maxwell'},
      {'pos': Offset(w * 0.42, h * 0.85), 'name': 'Pat Cummins'},
      {'pos': Offset(w * 0.58, h * 0.85), 'name': 'Mitchell Starc'},
      {'pos': Offset(w * 0.72, h * 0.60), 'name': 'Josh Hazlewood'},
      {'pos': Offset(w * 0.62, h * 0.35), 'name': 'Adam Zampa'},
    ];

    for (var f in fielders) {
      final pos = f['pos'] as Offset;
      final name = f['name'] as String;

      RealisticCricketAssets.drawCricketerFaceIdentity(
        canvas,
        pos,
        playerName: name,
        isIndia: isIndiaBowling,
        size: 16,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BroadcastStadiumPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ballState?.ballId != ballState?.ballId;
  }
}

// ---------------------------------------------------------------------------
// 2. HAWKEYE 3D BALL TRACKING PAINTER
// ---------------------------------------------------------------------------
class HawkeyeCameraPainter extends CustomPainter {
  final double progress;
  final BallState? ballState;

  HawkeyeCameraPainter({required this.progress, required this.ballState});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF040D1A).withOpacity(0.92));

    final gridPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.12)
      ..strokeWidth = 1.0;

    for (double i = 0; i < w; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, h), gridPaint);
    }
    for (double j = 0; j < h; j += 30) {
      canvas.drawLine(Offset(0, j), Offset(w, j), gridPaint);
    }

    final releasePos = Offset(w * 0.15, h * 0.45);
    final bouncePos = Offset(w * 0.55, h * 0.65);
    final stumpPos = Offset(w * 0.85, h * 0.52);

    RealisticCricketAssets.drawZingStumps(
      canvas,
      stumpPos,
      scale: 1.2,
      isWicketHit: (ballState?.isWicket ?? false) && progress > 0.6,
    );

    if (ballState != null) {
      RealisticCricketAssets.drawHawkeyeTrajectory(
        canvas,
        size,
        releasePos: releasePos,
        bouncePos: bouncePos,
        stumpPos: stumpPos,
        progress: progress,
        isWicket: ballState!.isWicket,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HawkeyeCameraPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ballState?.ballId != ballState?.ballId;
  }
}

// ---------------------------------------------------------------------------
// 3. PITCH RADAR PAINTER
// ---------------------------------------------------------------------------
class PitchRadarPainter extends CustomPainter {
  final double progress;
  final BallState? ballState;
  final String strikerName;
  final String bowlerName;

  PitchRadarPainter({
    required this.progress,
    required this.ballState,
    required this.strikerName,
    required this.bowlerName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF09111E).withOpacity(0.92));

    final gridPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(w / 2, h / 2);
    canvas.drawCircle(center, h * 0.2, gridPaint);
    canvas.drawCircle(center, h * 0.38, gridPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, h), gridPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(w, center.dy), gridPaint);

    final pitchW = 40.0;
    final pitchH = h * 0.7;
    final pitchRect = Rect.fromCenter(center: center, width: pitchW, height: pitchH);
    canvas.drawRect(pitchRect, Paint()..color = const Color(0xFF2C3E50));
    canvas.drawRect(pitchRect, Paint()..color = const Color(0xFF38BDF8).withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    if (ballState != null) {
      final runs = ballState!.runsOffBat;
      final shotAngle = ballState!.shotAngleRadians;

      final batterPos = Offset(center.dx, pitchRect.bottom - 15);
      final bouncePos = Offset(center.dx + (ballState!.ballId % 3 - 1) * 6, pitchRect.top + pitchH * 0.45);

      canvas.drawCircle(bouncePos, 5, Paint()..color = const Color(0xFFF59E0B));
      canvas.drawCircle(bouncePos, 9, Paint()..color = const Color(0xFFF59E0B).withOpacity(0.3));

      if (progress > 0.4) {
        final vecDist = (runs == 6 ? h * 0.4 : (runs == 4 ? h * 0.3 : h * 0.18)) * (progress - 0.4) / 0.6;
        final targetX = batterPos.dx + math.sin(shotAngle) * vecDist;
        final targetY = batterPos.dy - math.cos(shotAngle) * vecDist;

        final linePaint = Paint()
          ..color = runs == 6 ? const Color(0xFFF59E0B) : (runs == 4 ? const Color(0xFF10B981) : const Color(0xFF38BDF8))
          ..strokeWidth = 2.5;

        canvas.drawLine(batterPos, Offset(targetX, targetY), linePaint);
        canvas.drawCircle(Offset(targetX, targetY), 5, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PitchRadarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ballState?.ballId != ballState?.ballId;
  }
}
