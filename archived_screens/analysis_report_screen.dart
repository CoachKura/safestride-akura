// Screen to display comprehensive workout analysis with issues and remedies

import 'package:flutter/material.dart';
import '../services/workout_analysis_service.dart';

class AnalysisReportScreen extends StatelessWidget {
  final WorkoutAnalysis analysis;

  const AnalysisReportScreen({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Analysis Report'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
            // Overall Risk Score Card
            _buildRiskScoreCard(),

            // Quick Summary
            _buildQuickSummary(),

            // Critical Issues Section
            if (analysis.criticalIssues.isNotEmpty)
              _buildCriticalIssuesSection(),

            // Warning Issues Section
            if (analysis.warningIssues.isNotEmpty) _buildWarningIssuesSection(),

            // Strengths Section
            if (analysis.strengths.isNotEmpty) _buildStrengthsSection(),

            // Metrics Overview
            _buildMetricsSection(),

            // Action Plan Button
            _buildActionPlanButton(context),

            const SizedBox(height: 16),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildRiskScoreCard() {
    final score = analysis.overallRiskScore;
    Color scoreColor;
    String riskLevel;
    IconData icon;

    if (score >= 80) {
      scoreColor = Colors.green;
      riskLevel = 'LOW RISK';
      icon = Icons.check_circle;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      riskLevel = 'MODERATE RISK';
      icon = Icons.warning;
    } else {
      scoreColor = Colors.red;
      riskLevel = 'HIGH RISK';
      icon = Icons.error;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withValues(alpha: 0.8), scoreColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            riskLevel,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Injury Prevention Score',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            score.toString(),
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            '/ 100',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Quick Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            '🚨 Critical Issues',
            analysis.criticalIssues.length.toString(),
            Colors.red,
          ),
          _buildSummaryRow(
            '⚠️ Warnings',
            analysis.warningIssues.length.toString(),
            Colors.orange,
          ),
          _buildSummaryRow(
            '✅ Strengths',
            analysis.strengths.length.toString(),
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalIssuesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  '🚨 CRITICAL ISSUES - IMMEDIATE ATTENTION REQUIRED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...analysis.criticalIssues.map((issue) => _buildIssueCard(issue)),
        ],
      ),
    );
  }

  Widget _buildWarningIssuesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  '⚠️ WARNINGS - MONITOR AND IMPROVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...analysis.warningIssues.map((issue) => _buildIssueCard(issue)),
        ],
      ),
    );
  }

  Widget _buildIssueCard(AnalysisIssue issue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: issue.severityColor,
          width: 2,
        ),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(
            issue.severityIcon,
            color: issue.severityColor,
            size: 32,
          ),
          title: Text(
            issue.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: issue.severityColor,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${issue.category} • Current: ${issue.currentValue}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${issue.targetValue}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          children: [
            _buildDetailSection('⚠️ The Problem', issue.problem),
            const Divider(height: 24),
            _buildDetailSection('🔍 Why This Matters', issue.why),
            const Divider(height: 24),
            _buildDetailSection('✅ The Remedy', issue.remedy),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: issue.severityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎯 Protocol Focus Areas:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...issue.protocolFocus.map(
                    (focus) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: issue.severityColor,
                          ),
                          const SizedBox(width: 8),
                          Text(focus, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildStrengthsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.thumb_up, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Your Strengths',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...analysis.strengths.map(
            (strength) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                strength,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Key Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Cadence',
                '${analysis.metrics['avgCadence']?.toStringAsFixed(0) ?? '0'} spm',
                Icons.directions_run,
                Colors.blue,
              ),
              _buildMetricCard(
                'Weekly Distance',
                '${analysis.metrics['weeklyDistance']?.toStringAsFixed(1) ?? '0'} km',
                Icons.trending_up,
                Colors.purple,
              ),
              _buildMetricCard(
                'Vertical Osc.',
                '${analysis.metrics['verticalOscillation']?.toStringAsFixed(1) ?? '0'} cm',
                Icons.height,
                Colors.orange,
              ),
              _buildMetricCard(
                'Ground Contact',
                '${analysis.metrics['groundContactTime']?.toStringAsFixed(0) ?? '0'} ms',
                Icons.timer,
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionPlanButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to protocol generation screen
          Navigator.pop(context); // Go back and trigger protocol generation
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '🎯 Generate Personalized Protocol',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
