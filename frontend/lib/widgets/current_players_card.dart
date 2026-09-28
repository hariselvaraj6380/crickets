import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/match_state.dart';

class CurrentPlayersCard extends StatelessWidget {
  final MatchState matchState;

  const CurrentPlayersCard({Key? key, required this.matchState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final striker = matchState.striker;
    final nonStriker = matchState.nonStriker;
    final bowler = matchState.bowler;

    return Row(
      children: [
        // Batting Card
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BATTER ON CREASE',
                  style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                if (striker != null) _buildBatterRow(striker, isStriker: true),
                const Divider(color: Colors.white10, height: 16),
                if (nonStriker != null) _buildBatterRow(nonStriker, isStriker: false),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Bowling Card
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE BOWLER',
                  style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                if (bowler != null) ...[
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFF59E0B),
                        child: Icon(Icons.sports_cricket, size: 14, color: Colors.black),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bowler.name,
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn('Overs', bowler.overs),
                      _buildStatColumn('Runs', '${bowler.runsConceded}'),
                      _buildStatColumn('Wkts', '${bowler.wickets}'),
                      _buildStatColumn('Econ', bowler.economy.toStringAsFixed(1)),
                    ],
                  ),
                ] else
                  Text('No active bowler', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatterRow(PlayerState player, {required bool isStriker}) {
    return Row(
      children: [
        Icon(
          isStriker ? Icons.sports_baseball_rounded : Icons.person_outline,
          size: 16,
          color: isStriker ? const Color(0xFF38BDF8) : Colors.white38,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${player.name}${isStriker ? ' *' : ''}',
            style: GoogleFonts.outfit(
              color: isStriker ? Colors.white : Colors.white70,
              fontWeight: isStriker ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${player.runs}',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
          ' (${player.balls}b)',
          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'SR ${player.strikeRate.toStringAsFixed(0)}',
            style: GoogleFonts.inter(color: const Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
