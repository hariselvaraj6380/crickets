import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/match_state.dart';

class RecentBallsStrip extends StatelessWidget {
  final List<BallState> balls;

  const RecentBallsStrip({Key? key, required this.balls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (balls.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Over starting...', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECENT DELIVERIES',
            style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: balls.map((ball) => _buildBallChip(ball)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBallChip(BallState ball) {
    Color bg = const Color(0xFF334155);
    Color fg = Colors.white;
    Border? border;

    if (ball.isWicket) {
      bg = const Color(0xFFEF4444);
      fg = Colors.white;
    } else if (ball.displayLabel.contains('6')) {
      bg = const Color(0xFF8B5CF6);
      fg = Colors.white;
    } else if (ball.displayLabel.contains('4')) {
      bg = const Color(0xFF0284C7);
      fg = Colors.white;
    } else if (ball.displayLabel.contains('Wd') || ball.displayLabel.contains('Nb')) {
      bg = const Color(0xFFD97706);
      fg = Colors.white;
    } else if (ball.runsOffBat == 0) {
      bg = const Color(0xFF1E293B);
      fg = const Color(0xFF94A3B8);
      border = Border.all(color: Colors.white24);
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border,
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        ball.displayLabel,
        style: GoogleFonts.outfit(color: fg, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
