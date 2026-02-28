// Report Viewer Screen
//
// Dedicated screen for viewing comprehensive assessment reports
// with timeline visualization, sharing, and export capabilities

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/assessment_report_generator.dart';
import '../widgets/roadmap_timeline_widget.dart' as timeline;
import 'phase_details_screen.dart';

class ReportViewerScreen extends StatefulWidget {
  final AssessmentReport report;

  const ReportViewerScreen({
    super.key,
    required this.report,
  });

  @override
  _ReportViewerScreenState createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends State<ReportViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentWeek = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Report',
            onPressed: _refreshReport,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Report',
            onPressed: _shareReport,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_text',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Copy Text Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Print Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.summarize), text: 'Summary'),
            Tab(icon: Icon(Icons.timeline), text: 'Roadmap'),
            Tab(icon: Icon(Icons.article), text: 'Full Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildRoadmapTab(),
          _buildFullReportTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startRecoveryProgram,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Program'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExecutiveSummaryCard(),
          const SizedBox(height: 16),
          _buildGoalCard(),
          const SizedBox(height: 16),
          _buildKeyMetricsCard(),
          const SizedBox(height: 16),
          _buildNextStepsCard(),
        ],
        ),
      ),
    );
  }

  Widget _buildExecutiveSummaryCard() {
    final summary = widget.report.executiveSummary;
    Color riskColor = _getRiskColor(summary.overallRiskLevel);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: riskColor, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Executive Summary',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // AISRI Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AISRI Score:', style: TextStyle(fontSize: 16)),
                Text(
                  '${summary.aistriScore}/100',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Risk Level Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: riskColor, width: 2),
              ),
              child: Text(
                '${summary.overallRiskLevel} Risk Level',
                style: TextStyle(
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recovery Timeline
            Row(
              children: [
                const Icon(Icons.schedule, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Estimated Recovery: ${summary.estimatedRecoveryWeeks} weeks',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),

            // Critical Findings
            if (summary.criticalFindings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                '⚠️ Critical Findings:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...summary.criticalFindings.map((finding) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(color: Colors.red, fontSize: 16)),
                        Expanded(
                          child: Text(finding,
                              style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.flag, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Your Goal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.report.executiveSummary.goalStatement,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsCard() {
    final summary = widget.report.executiveSummary;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pillar Scores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...summary.pillarScores.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildMetricRow(entry.key, entry.value),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, int value) {
    Color color = value >= 80
        ? Colors.green
        : value >= 60
            ? Colors.orange
            : Colors.red;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          flex: 5,
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepsCard() {
    return Card(
      color: Colors.blue[50],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Next Steps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.report.nextStepsRecommendation,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapTab() {
    return Column(
      children: [
        // Week Selector
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Text('Current Week:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: _currentWeek,
                items: List.generate(
                  widget.report.recoveryRoadmap.totalWeeks + 1,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text('Week $index'),
                  ),
                ),
                onChanged: (week) {
                  setState(() {
                    _currentWeek = week ?? 0;
                  });
                },
              ),
            ],
          ),
        ),

        // Timeline Widget
        Expanded(
          child: timeline.RoadmapTimelineWidget(
            phases: widget.report.recoveryRoadmap.phases.map((phase) {
              return timeline.TimelinePhase(
                name: phase.phaseName,
                weekRange: phase.weekRange,
                goals: phase.goals,
                expectedImprovements: phase.expectedImprovements,
                focusAreas: phase.focusAreas,
              );
            }).toList(),
            milestones: widget.report.milestones.map((milestone) {
              return timeline.Milestone(
                weekNumber: milestone.weekNumber,
                title: milestone.title,
                targetDate: milestone.targetDate,
                expectedImprovements: milestone.expectedImprovements,
                isCompleted: milestone.isCompleted,
              );
            }).toList(),
            currentWeek: _currentWeek,
            onPhaseClicked: (phaseIndex) {
              _navigateToPhaseDetails(phaseIndex);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFullReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyReportText,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy to Clipboard'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportToPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              widget.report.generateTextReport(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return Colors.green;
      case 'Moderate':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Critical':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  void _navigateToPhaseDetails(int phaseIndex) {
    final phase = widget.report.recoveryRoadmap.phases[phaseIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhaseDetailsScreen(
          phase: phase,
          phaseNumber: phaseIndex + 1,
        ),
      ),
    );
  }

  void _refreshReport() {
    setState(() {
      // Refresh the report data
      // In a real app, you'd fetch updated assessment data here
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report refreshed!')),
    );
  }

  void _shareReport() {
    // TODO: Implement share functionality using share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_pdf':
        _exportToPDF();
        break;
      case 'copy_text':
        _copyReportText();
        break;
      case 'print':
        _printReport();
        break;
    }
  }

  void _exportToPDF() {
    // TODO: Implement PDF export using pdf package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export coming soon!')),
    );
  }

  void _copyReportText() {
    Clipboard.setData(ClipboardData(text: widget.report.generateTextReport()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _printReport() {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon!')),
    );
  }

  void _startRecoveryProgram() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Recovery Program'),
        content: const Text(
          'This will activate your personalized recovery program and begin '
          'tracking your progress. Are you ready to start?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to recovery program screen
              Navigator.pushNamed(context, '/recovery-program');
            },
            child: const Text('Start Now!'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
