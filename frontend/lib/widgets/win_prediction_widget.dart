import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/match_state.dart';

class WinPredictionWidget extends StatelessWidget {
  final MatchState matchState;

  const WinPredictionWidget({Key? key, required this.matchState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pred = matchState.prediction;
    final double team1Pct = pred.winProbabilityTeam1;
    final double team2Pct = pred.winProbabilityTeam2;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Color(0xFF38BDF8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'AI Win Probability Engine',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (pred.projectedScore > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                  ),
                  child: Text(
                    'Projected Total: ${pred.projectedScore}',
                    style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Percentage Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${matchState.team1}: ${team1Pct.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                  color: team1Pct >= 50 ? const Color(0xFF38BDF8) : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${matchState.team2}: ${team2Pct.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                  color: team2Pct >= 50 ? const Color(0xFFF59E0B) : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Win Probability Dual Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (team1Pct * 10).toInt(),
                    child: Container(color: const Color(0xFF38BDF8)),
                  ),
                  Expanded(
                    flex: (team2Pct * 10).toInt(),
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ),
          ),

          if (pred.explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '💡 ${pred.explanation}',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
