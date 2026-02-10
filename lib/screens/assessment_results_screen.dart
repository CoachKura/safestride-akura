// Assessment Results Screen
//
// Comprehensive post-assessment screen showing:
// - AISRI score and pillar breakdown
// - Gait pathology analysis
// - Detailed ROM findings with biomechanical impact
// - Visual recovery roadmap
// - Specific corrective protocols
// - Next steps and action items

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../services/gait_pathology_analyzer.dart'
    show GaitPathology, GaitPathologyAnalyzer, Exercise;
import '../services/assessment_report_generator.dart'
    show AssessmentReport, AssessmentReportGenerator, InjuryRisk, RoadmapPhase;
import '../widgets/roadmap_timeline_widget.dart' show RoadmapTimelineWidget;
import '../widgets/roadmap_timeline_widget.dart' as timeline;
import 'athlete_goals_screen.dart';
import '../services/kura_coach_service.dart';

class AssessmentResultsScreen extends StatefulWidget {
  final Map<String, dynamic> assessmentData;
  final int aistriScore;
  final Map<String, int> pillarScores;

  const AssessmentResultsScreen({
    super.key,
    required this.assessmentData,
    required this.aistriScore,
    required this.pillarScores,
  });

  @override
  _AssessmentResultsScreenState createState() =>
      _AssessmentResultsScreenState();
}

class _AssessmentResultsScreenState extends State<AssessmentResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<GaitPathology> gaitPathologies;
  late AssessmentReport report;
  List<GaitPathology>? _gaitPathologies;
  AssessmentReport? _report;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _analyzeAssessment();
  }

  void _analyzeAssessment() async {
    // Analyze gait patterns
    gaitPathologies =
        GaitPathologyAnalyzer.analyzeGaitPatterns(widget.assessmentData);
    _gaitPathologies = gaitPathologies;

    // Generate comprehensive report
    // Note: You'll need to create InjuryRiskAnalyzer.analyze() method
    final injuryRisks = _mockInjuryRisks(); // Placeholder for now

    report = AssessmentReportGenerator.generateReport(
      athleteId: widget.assessmentData['user_id'] ?? 'unknown',
      assessmentData: widget.assessmentData,
      aistriScore: widget.aistriScore,
      pillarScores: widget.pillarScores,
      injuryRisks: injuryRisks,
      gaitPathologies: gaitPathologies,
      goalStatement:
          widget.assessmentData['goals'] ?? 'Improve running performance',
    );
    _report = report;
  }

  // Placeholder - replace with actual InjuryRiskAnalyzer call
  List<InjuryRisk> _mockInjuryRisks() {
    // This should be replaced with actual injury risk analysis
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/dashboard', (route) => false);
          },
          tooltip: 'Return to Dashboard',
        ),
        title: const Text('Assessment Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadReport,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Gait Analysis'),
            Tab(text: 'Roadmap'),
            Tab(text: 'Full Report'),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main content
          TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildGaitAnalysisTab(),
              _buildRoadmapTab(),
              _buildFullReportTab(),
            ],
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Generating your training protocol...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF667EEA),
          unselectedItemColor: Colors.grey,
          currentIndex: 0,
          onTap: (index) {
            switch (index) {
              case 0: // Home
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/dashboard', (route) => false);
                break;
              case 1: // Track
                Navigator.pushNamed(context, '/tracker');
                break;
              case 2: // Log
                Navigator.pushNamed(context, '/logger');
                break;
              case 3: // History
                Navigator.pushNamed(context, '/history');
                break;
              case 4: // Profile
                Navigator.pushNamed(context, '/profile');
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.track_changes_outlined),
              activeIcon: Icon(Icons.track_changes),
              label: 'Track',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_outlined),
              activeIcon: Icon(Icons.edit_note),
              label: 'Log',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AISRI Score Card
          _buildAISTRIScoreCard(),

          const SizedBox(height: 24),

          // Training Protocol Generation
          _buildTrainingProtocolCard(),

          const SizedBox(height: 24),

          // Critical Findings
          _buildCriticalFindings(),

          const SizedBox(height: 24),

          // Pillar Breakdown
          _buildPillarBreakdown(),

          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(),
        ],
        ),
      ),
    );
  }

  Widget _buildAISTRIScoreCard() {
    Color scoreColor = widget.aistriScore >= 80
        ? Colors.green
        : widget.aistriScore >= 65
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              scoreColor.withValues(alpha: 0.1),
              scoreColor.withValues(alpha: 0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Your AISRI Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Circular score indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: widget.aistriScore / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${widget.aistriScore}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              '${report.executiveSummary.overallRiskLevel} Risk Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Estimated Recovery: ${report.executiveSummary.estimatedRecoveryWeeks} weeks',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalFindings() {
    if (report.executiveSummary.criticalFindings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No critical findings detected! Continue with preventive care.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red[700], size: 28),
                const SizedBox(width: 8),
                Text(
                  'Critical Findings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...report.executiveSummary.criticalFindings.map((finding) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔴 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        finding,
                        style: TextStyle(fontSize: 14, color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(2), // Go to Roadmap tab
              icon: const Icon(Icons.medical_services),
              label: const Text('View Corrective Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '6-Pillar Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.pillarScores.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildPillarBar(entry.key, entry.value),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarBar(String pillarName, int score) {
    Color barColor = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              pillarName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              '$score/100',
              style: TextStyle(
                  fontSize: 14, color: barColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.fitness_center,
          label: 'Start Rehab Program',
          color: Colors.blue,
          onPressed: () {
            // Navigate to rehab program screen
            Navigator.pushNamed(context, '/rehab-program');
          },
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: Icons.map,
          label: 'View Recovery Roadmap',
          color: Colors.green,
          onPressed: () => _tabController.animateTo(2),
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: Icons.directions_run,
          label: 'Adjust Training Plan',
          color: Colors.orange,
          onPressed: () {
            // Navigate to training plan screen
            Navigator.pushNamed(context, '/training-plan');
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildGaitAnalysisTab() {
    if (gaitPathologies.isEmpty) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'No Significant Gait Pathologies Detected',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Your gait pattern appears to be within normal parameters.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
        ),
      );
    }

    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: gaitPathologies.length,
      itemBuilder: (context, index) {
        final pathology = gaitPathologies[index];
        return _buildGaitPathologyCard(pathology);
      },
      ),
    );
  }

  Widget _buildGaitPathologyCard(GaitPathology pathology) {
    Color severityColor = pathology.severity == 'Severe'
        ? Colors.red
        : pathology.severity == 'Moderate'
            ? Colors.orange
            : Colors.yellow[700]!;

    String pathologyName = _getPathologyName(pathology.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(Icons.error_outline, color: severityColor, size: 32),
        title: Text(
          pathologyName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${pathology.severity} - ${(pathology.confidenceLevel * 100).toStringAsFixed(0)}% confidence',
          style: TextStyle(color: severityColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Biomechanics Explanation:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  pathology.mechanismDescription,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Associated Injuries:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...pathology.associatedInjuries.take(5).map((injury) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.red)),
                        Expanded(
                            child: Text(injury,
                                style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'Corrective Strategy:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  pathology.correctiveStrategy,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showExerciseDetails(pathology),
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('View Corrective Exercises'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: severityColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPathologyName(String type) {
    switch (type) {
      case 'bow_legs':
        return 'Bow Legs (Genu Varum)';
      case 'knock_knees':
        return 'Knock Knees (Genu Valgum)';
      case 'overpronation':
        return 'Overpronation';
      case 'underpronation':
        return 'Underpronation (Supination)';
      default:
        return type;
    }
  }

  void _showExerciseDetails(GaitPathology pathology) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Corrective Exercises',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ...pathology.specificExercises.map((exercise) {
                  return _buildExerciseCard(exercise);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(exercise.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildExerciseDetail('Sets', '${exercise.sets}'),
                const SizedBox(width: 16),
                _buildExerciseDetail('Reps', '${exercise.reps}'),
                const SizedBox(width: 16),
                Expanded(
                    child:
                        _buildExerciseDetail('Frequency', exercise.frequency)),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Progression Timeline',
                  style: TextStyle(fontSize: 14)),
              children: [
                Text(exercise.progressionTimeline,
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRoadmapTab() {
    return SafeArea(
      child: SingleChildScrollView(
        child: RoadmapTimelineWidget(
        phases: report.recoveryRoadmap.phases.map((phase) {
          return timeline.TimelinePhase(
            name: phase.phaseName,
            weekRange: phase.weekRange,
            goals: phase.goals,
            expectedImprovements: phase.expectedImprovements,
            focusAreas: phase.focusAreas,
          );
        }).toList(),
        milestones: report.milestones.map<timeline.Milestone>((milestone) {
          return timeline.Milestone(
            weekNumber: milestone.weekNumber,
            title: milestone.title,
            targetDate: milestone.targetDate,
            expectedImprovements: milestone.expectedImprovements,
            isCompleted: milestone.isCompleted,
          );
        }).toList(),
        currentWeek: 0,
        onPhaseClicked: (phaseIndex) {
          // Show phase details
          _showPhaseDetails(report.recoveryRoadmap.phases[phaseIndex]);
        },
      ),
      ),
    );
  }

  void _showPhaseDetails(RoadmapPhase phase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Phase ${phase.phaseNumber}: ${phase.phaseName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Week Range: ${phase.weekRange}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Goals:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...phase.goals.map((goal) => Text('• $goal')),
              const SizedBox(height: 12),
              const Text('Training Modifications:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...phase.trainingModifications.map((mod) => Text('• $mod')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFullReportTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              report.generateTextReport(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _shareReport() async {
    try {
      final reportText = _generateShareableReport();
      await Share.share(
        reportText,
        subject:
            'AISRI Assessment Report - ${DateTime.now().toString().split(' ')[0]}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing report: $e')),
        );
      }
    }
  }

  String _generateShareableReport() {
    final buffer = StringBuffer();
    buffer.writeln('🏃 AISRI ASSESSMENT REPORT');
    buffer.writeln('=' * 50);
    buffer.writeln('');
    buffer.writeln('📊 AISRI Score: ${widget.aistriScore}/100');
    buffer.writeln('');
    buffer.writeln('📈 PILLAR SCORES:');
    widget.pillarScores.forEach((pillar, score) {
      buffer.writeln('  • $pillar: $score/100');
    });
    buffer.writeln('');

    if (_gaitPathologies != null && _gaitPathologies!.isNotEmpty) {
      buffer.writeln('🔍 GAIT ANALYSIS:');
      for (var pathology in _gaitPathologies!) {
        buffer.writeln('  ⚠️ ${pathology.pathologyName}');
        buffer.writeln('     Severity: ${pathology.severity}');
      }
      buffer.writeln('');
    }

    buffer.writeln('💡 Next Steps:');
    buffer.writeln(_report?.nextStepsRecommendation ??
        'Follow the recommended recovery program');
    buffer.writeln('');
    buffer.writeln('Generated by Akura SafeStride');
    buffer.writeln('https://akurasafestride.com');

    return buffer.toString();
  }

  void _downloadReport() async {
    try {
      final pdf = pw.Document();

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'AISRI Assessment Report',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),

            // AISRI Score
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'AISRI Score: ${widget.aistriScore}/100',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Date: ${DateTime.now().toString().split(' ')[0]}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Pillar Scores
            pw.Header(
              level: 1,
              child: pw.Text('Pillar Scores'),
            ),
            pw.SizedBox(height: 10),
            ...widget.pillarScores.entries.map((entry) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(entry.key),
                      ),
                      pw.Expanded(
                        flex: 7,
                        child: pw.Container(
                          height: 10,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                          ),
                          child: pw.Stack(
                            children: [
                              pw.Container(
                                width: (entry.value / 100) *
                                    500, // Approximate width
                                color: PdfColors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text('${entry.value}'),
                    ],
                  ),
                )),
            pw.SizedBox(height: 20),

            // Gait Analysis
            if (_gaitPathologies != null && _gaitPathologies!.isNotEmpty) ...[
              pw.Header(
                level: 1,
                child: pw.Text('Gait Analysis'),
              ),
              pw.SizedBox(height: 10),
              ..._gaitPathologies!.map((pathology) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          pathology.pathologyName,
                          style: pw.TextStyle(
                              fontSize: 14, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Severity: ${pathology.severity}'),
                        pw.SizedBox(height: 4),
                        pw.Text(
                            'Confidence: ${(pathology.confidence * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 20),
            ],

            // Full Report
            pw.Header(
              level: 1,
              child: pw.Text('Complete Assessment Report'),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              _report?.generateTextReport() ?? 'Report data unavailable',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      );

      // Save PDF
      final bytes = await pdf.save();

      if (kIsWeb) {
        // Web: Show print dialog
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
        );
      } else {
        // Mobile: Share the PDF file
        final tempDir = await getTemporaryDirectory();
        final file = File(
            '${tempDir.path}/aisri_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'AISRI Assessment Report',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTrainingProtocolCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Colors.blue[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Start Your Training Journey',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Based on your AISRI assessment, we can create a personalized training protocol tailored to your fitness level and goals.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateTrainingProtocol,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isLoading ? 'Generating...' : 'Generate My Training Protocol',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateTrainingProtocol() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get evaluation data from assessment
      final evaluationData = {
        'AISRI_score': widget.aistriScore,
        'fitness_level': _determineFitnessLevel(widget.aistriScore.toDouble()),
        'injury_risk': report.executiveSummary.overallRiskLevel,
        'assessment_date': widget.assessmentData['created_at'] ?? DateTime.now().toIso8601String(),
        'pillar_scores': {
          'mobility': widget.pillarScores['Mobility'] ?? 0,
          'stability': widget.pillarScores['Stability'] ?? 0,
          'strength': widget.pillarScores['Strength'] ?? 0,
          'power': widget.pillarScores['Power'] ?? 0,
          'endurance': widget.pillarScores['Endurance'] ?? 0,
        },
      };

      // Generate protocol using Kura Coach service
      await KuraCoachService.generateProtocolFromEvaluation(
        athleteId: userId,
        evaluationData: evaluationData,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('Protocol Generated!'),
            ],
          ),
          content: Text(
            'Your personalized training protocol has been created. '
            'Let\'s set up your athlete profile and goals to get started.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToAthleteGoals();
              },
              child: Text('Set Up Profile'),
            ),
          ],
        ),
      );

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Text('Generation Failed'),
            ],
          ),
          content: Text('Error: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _determineFitnessLevel(double AISRIScore) {
    if (AISRIScore >= 80) return 'advanced';
    if (AISRIScore >= 60) return 'intermediate';
    return 'beginner';
  }

  void _navigateToAthleteGoals() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AthleteGoalsScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
