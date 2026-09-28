import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/match_state.dart';

class SimulationControls extends StatelessWidget {
  final MatchState matchState;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStep;
  final VoidCallback onReset;
  final Function(double) onSpeedChanged;
  final Function(int runs, String extraType, String wicketType) onInjectBall;

  const SimulationControls({
    Key? key,
    required this.matchState,
    required this.onPlay,
    required this.onPause,
    required this.onStep,
    required this.onReset,
    required this.onSpeedChanged,
    required this.onInjectBall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isRunning = matchState.isSimulating;

    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                'SIMULATION CONTROLLER',
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),

              // Manual Ball Injector Trigger Button
              ElevatedButton.icon(
                onPressed: () => _showManualBallModal(context),
                icon: const Icon(Icons.add_circle_outline, size: 14, color: Color(0xFF10B981)),
                label: Text(
                  'Manual Ball',
                  style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              // Play / Pause Button
              IconButton.filled(
                onPressed: isRunning ? onPause : onPlay,
                icon: Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: isRunning ? Colors.amber : const Color(0xFF10B981),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 10),

              // Step Button
              IconButton.filledTonal(
                onPressed: onStep,
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 22),
                tooltip: 'Simulate Next Ball',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 10),

              // Reset Button
              IconButton.filledTonal(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded, color: Colors.white70, size: 22),
                tooltip: 'Reset Match',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),

              const Spacer(),

              // Speed Multiplier Toggles
              Row(
                children: [1.0, 2.0, 5.0, 10.0].map((speed) {
                  final isSelected = (matchState.speedMultiplier - speed).abs() < 0.1;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ChoiceChip(
                      label: Text('${speed.toInt()}x'),
                      selected: isSelected,
                      onSelected: (_) => onSpeedChanged(speed),
                      selectedColor: const Color(0xFF38BDF8),
                      backgroundColor: Colors.white.withOpacity(0.05),
                      labelStyle: GoogleFonts.outfit(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showManualBallModal(BuildContext context) {
    int selectedRuns = 0;
    String selectedExtra = 'NONE';
    String selectedWicket = 'NONE';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inject Manual Delivery',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Runs Selection
                  Text('Runs off bat:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [0, 1, 2, 3, 4, 6].map((r) {
                      final isSel = selectedRuns == r;
                      return ChoiceChip(
                        label: Text('$r'),
                        selected: isSel,
                        onSelected: (_) => setModalState(() => selectedRuns = r),
                        selectedColor: const Color(0xFF38BDF8),
                        backgroundColor: Colors.white10,
                        labelStyle: GoogleFonts.outfit(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Extra Selection
                  Text('Extra type:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['NONE', 'WIDE', 'NO_BALL', 'BYE', 'LEG_BYE'].map((ext) {
                      final isSel = selectedExtra == ext;
                      return ChoiceChip(
                        label: Text(ext),
                        selected: isSel,
                        onSelected: (_) => setModalState(() => selectedExtra = ext),
                        selectedColor: Colors.amber,
                        backgroundColor: Colors.white10,
                        labelStyle: GoogleFonts.outfit(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Wicket Selection
                  Text('Wicket status:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['NONE', 'BOWLED', 'CAUGHT', 'LBW', 'RUN_OUT'].map((w) {
                      final isSel = selectedWicket == w;
                      return ChoiceChip(
                        label: Text(w),
                        selected: isSel,
                        onSelected: (_) => setModalState(() => selectedWicket = w),
                        selectedColor: Colors.redAccent,
                        backgroundColor: Colors.white10,
                        labelStyle: GoogleFonts.outfit(color: isSel ? Colors.white : Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onInjectBall(selectedRuns, selectedExtra, selectedWicket);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Submit Delivery', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
