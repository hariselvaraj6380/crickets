import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/match_state.dart';

class ScoreboardHeader extends StatelessWidget {
  final MatchState matchState;
  final VoidCallback onOpenScorecard;

  const ScoreboardHeader({
    Key? key,
    required this.matchState,
    required this.onOpenScorecard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = matchState.status == 'COMPLETED';
    final bool isSecondInnings = matchState.currentInningsNumber == 2;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top bar: Status Pill & Scorecard Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.purple.withOpacity(0.2)
                      : (matchState.isSimulating ? const Color(0xFF10B981).withOpacity(0.2) : Colors.amber.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.purpleAccent
                        : (matchState.isSimulating ? const Color(0xFF10B981) : Colors.amber),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.purpleAccent
                            : (matchState.isSimulating ? const Color(0xFF10B981) : Colors.amber),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCompleted
                          ? 'MATCH COMPLETED'
                          : (matchState.isSimulating ? 'LIVE SIMULATION' : 'SIMULATION PAUSED'),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              ElevatedButton.icon(
                onPressed: onOpenScorecard,
                icon: const Icon(Icons.table_chart_rounded, size: 16, color: Color(0xFF38BDF8)),
                label: Text(
                  'Full Scorecard',
                  style: GoogleFonts.outfit(color: const Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8).withOpacity(0.1),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFF38BDF8), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main Score Display Row
          Row(
            children: [
              // Team 1 Logo & Name
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF38BDF8).withOpacity(0.2),
                      child: Text(
                        matchState.team1.substring(0, 2).toUpperCase(),
                        style: GoogleFonts.outfit(color: const Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      matchState.team1,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: matchState.battingTeam == matchState.team1 ? FontWeight.bold : FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // Score Numbers Center Display
              Column(
                children: [
                  Text(
                    '${matchState.totalRuns} / ${matchState.wickets}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Overs: ${matchState.oversFormatted} / ${matchState.totalOvers}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isSecondInnings && matchState.targetRuns > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Target: ${matchState.targetRuns} runs (${matchState.targetRuns - matchState.totalRuns} needed)',
                        style: GoogleFonts.inter(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]
                ],
              ),

              // Team 2 Logo & Name
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFF59E0B).withOpacity(0.2),
                      child: Text(
                        matchState.team2.substring(0, 2).toUpperCase(),
                        style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      matchState.team2,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: matchState.battingTeam == matchState.team2 ? FontWeight.bold : FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Run Rate Badges & Winner Summary
          if (isCompleted && matchState.resultSummary.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Text(
                '🏆 ${matchState.resultSummary}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMetricChip('CRR', matchState.currentRunRate.toStringAsFixed(2), const Color(0xFF38BDF8)),
                if (isSecondInnings) ...[
                  const SizedBox(width: 16),
                  _buildMetricChip('RRR', matchState.requiredRunRate.toStringAsFixed(2), Colors.amberAccent),
                ],
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text('$label: ', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.outfit(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
