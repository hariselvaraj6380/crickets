import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

class ScorecardDialog extends StatefulWidget {
  final ApiService apiService;

  const ScorecardDialog({Key? key, required this.apiService}) : super(key: key);

  @override
  State<ScorecardDialog> createState() => _ScorecardDialogState();
}

class _ScorecardDialogState extends State<ScorecardDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? scorecardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadScorecard();
  }

  Future<void> _loadScorecard() async {
    final data = await widget.apiService.fetchScorecard();
    if (mounted) {
      setState(() {
        scorecardData = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inningsList = (scorecardData?['innings'] as List?) ?? [];

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Dialog Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Full Match Scorecard',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
              )
            else if (inningsList.isEmpty)
              const Expanded(
                child: Center(child: Text('No scorecard data available', style: TextStyle(color: Colors.white54))),
              )
            else ...[
              // Innings Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF38BDF8),
                labelColor: const Color(0xFF38BDF8),
                unselectedLabelColor: Colors.white60,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  Tab(text: '1st Innings: ${inningsList[0]['battingTeam']} (${inningsList[0]['totalRuns']}/${inningsList[0]['wickets']})'),
                  Tab(text: '2nd Innings: ${inningsList[1]['battingTeam']} (${inningsList[1]['totalRuns']}/${inningsList[1]['wickets']})'),
                ],
              ),

              const SizedBox(height: 12),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInningsScorecard(inningsList[0]),
                    _buildInningsScorecard(inningsList[1]),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInningsScorecard(Map<String, dynamic> inn) {
    final batters = (inn['batters'] as List?) ?? [];
    final bowlers = (inn['bowlers'] as List?) ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batting Table Section
          Text('BATTING', style: GoogleFonts.outfit(color: const Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 36,
              dataRowHeight: 40,
              columns: [
                DataColumn(label: Text('Batter', style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Dismissal', style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('R', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('B', style: GoogleFonts.outfit(color: Colors.white70))),
                DataColumn(label: Text('4s', style: GoogleFonts.outfit(color: Colors.white70))),
                DataColumn(label: Text('6s', style: GoogleFonts.outfit(color: Colors.white70))),
                DataColumn(label: Text('SR', style: GoogleFonts.outfit(color: Colors.white70))),
              ],
              rows: batters.map((b) {
                return DataRow(cells: [
                  DataCell(Text(b['name'], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataCell(Text(b['isOut'] ? b['dismissalInfo'] : 'not out', style: GoogleFonts.inter(color: b['isOut'] ? Colors.redAccent : const Color(0xFF10B981), fontSize: 12))),
                  DataCell(Text('${b['runs']}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataCell(Text('${b['balls']}', style: GoogleFonts.inter(color: Colors.white70))),
                  DataCell(Text('${b['fours']}', style: GoogleFonts.inter(color: Colors.white70))),
                  DataCell(Text('${b['sixes']}', style: GoogleFonts.inter(color: Colors.white70))),
                  DataCell(Text('${b['strikeRate']}', style: GoogleFonts.inter(color: const Color(0xFF38BDF8)))),
                ]);
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Bowling Table Section
          Text('BOWLING', style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DataTable(
              columnSpacing: 20,
              headingRowHeight: 36,
              dataRowHeight: 40,
              columns: [
                DataColumn(label: Text('Bowler', style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Overs', style: GoogleFonts.outfit(color: Colors.white70))),
                DataColumn(label: Text('Runs', style: GoogleFonts.outfit(color: Colors.white70))),
                DataColumn(label: Text('Wkts', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Econ', style: GoogleFonts.outfit(color: Colors.white70))),
              ],
              rows: bowlers.map((b) {
                return DataRow(cells: [
                  DataCell(Text(b['name'], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                  DataCell(Text('${b['overs']}', style: GoogleFonts.inter(color: Colors.white70))),
                  DataCell(Text('${b['runsConceded']}', style: GoogleFonts.inter(color: Colors.white70))),
                  DataCell(Text('${b['wickets']}', style: GoogleFonts.outfit(color: Colors.amberAccent, fontWeight: FontWeight.bold))),
                  DataCell(Text('${b['economy']}', style: GoogleFonts.inter(color: Colors.white70))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
