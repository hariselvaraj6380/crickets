import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/match_state.dart';

class CommentaryStream extends StatelessWidget {
  final List<BallState> balls;

  const CommentaryStream({Key? key, required this.balls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reversedList = balls.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 8),
              Text(
                'BALL-BY-BALL COMMENTARY',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (reversedList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Waiting for first ball...', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reversedList.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 16),
              itemBuilder: (ctx, idx) {
                final ball = reversedList[idx];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Over & Ball Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${ball.overNumber}.${ball.ballInOver}',
                        style: GoogleFonts.outfit(color: const Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Commentary Text
                    Expanded(
                      child: Text(
                        ball.commentary,
                        style: GoogleFonts.inter(
                          color: ball.isWicket ? Colors.redAccent : (ball.runsOffBat >= 4 ? Colors.amber : Colors.white70),
                          fontWeight: ball.isWicket || ball.runsOffBat >= 4 ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Delivery Result Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ball.isWicket ? Colors.red : (ball.runsOffBat >= 4 ? Colors.purple : Colors.white10),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ball.displayLabel,
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
