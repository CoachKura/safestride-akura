import 'package:flutter/material.dart';

class SafetyGatesScreen extends StatelessWidget {
  final Map<String, dynamic> aisriData;
  final Map<String, dynamic> safetyGates;

  const SafetyGatesScreen({
    super.key,
    required this.aisriData,
    required this.safetyGates,
  });

  @override
  Widget build(BuildContext context) {
    final powerGate = safetyGates['power'] as Map<String, dynamic>;
    final speedGate = safetyGates['speed'] as Map<String, dynamic>;
    final allowedZones = List<String>.from(aisriData['allowed_zones']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Gates'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange[700]!,
                      Colors.red[700]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Zone Safety Gates',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'High-intensity zones (Power & Speed) are locked until you meet specific safety requirements. This prevents injury from premature intensity.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Power Zone Gate
            _buildGateCard(
              context: context,
              zoneName: 'Power Zone (P)',
              zoneDescription: 'High-intensity intervals at 87-95% max HR',
              zoneColor: const Color(0xFFFF6B6B),
              gate: powerGate,
              isUnlocked: allowedZones.contains('P'),
              icon: Icons.flash_on,
            ),

            const SizedBox(height: 16),

            // Speed Zone Gate
            _buildGateCard(
              context: context,
              zoneName: 'Speed Zone (SP)',
              zoneDescription: 'Sprint work at 95-100% max HR',
              zoneColor: const Color(0xFF8B0000),
              gate: speedGate,
              isUnlocked: allowedZones.contains('SP'),
              icon: Icons.speed,
            ),

            const SizedBox(height: 24),

            // Tips Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Colors.amber[700], size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'How to Unlock',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTip(
                      'Build Your Foundation',
                      'Spend time in lower zones (AR, F, EN, TH) to build aerobic capacity and running economy.',
                      Icons.foundation,
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      'Improve All Pillars',
                      'Work on strength, mobility, balance, and ROM through targeted exercises and assessments.',
                      Icons.fitness_center,
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      'Manage Load',
                      'Keep your Acute:Chronic load ratio between 0.8-1.3 to avoid overtraining.',
                      Icons.trending_up,
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      'Stay Injury-Free',
                      'Address any injuries promptly and allow proper recovery time before intense work.',
                      Icons.healing,
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      'Perfect Your Form',
                      'Work with coaches or use video analysis to ensure proper running mechanics.',
                      Icons.videocam,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Why Safety Gates Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Why Safety Gates?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The AISRI system uses safety gates to implement the "Economical Runner" philosophy. Research shows that 80% of running injuries result from:',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    _buildBulletPoint('Premature high-intensity training'),
                    _buildBulletPoint('Insufficient aerobic base development'),
                    _buildBulletPoint('Poor biomechanics and running form'),
                    _buildBulletPoint('Inadequate strength and mobility'),
                    _buildBulletPoint('Rapid load increases (>10% per week)'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'By progressing systematically through the zones, you build a durable, efficient, and injury-resistant running system.',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGateCard({
    required BuildContext context,
    required String zoneName,
    required String zoneDescription,
    required Color zoneColor,
    required Map<String, dynamic> gate,
    required bool isUnlocked,
    required IconData icon,
  }) {
    final requirements = gate['requirements_met'] as Map<String, dynamic>;
    final requirementsList = requirements.entries.toList();
    final metCount = requirements.values.where((v) => v == true).length;
    final totalCount = requirements.length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: zoneColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: zoneColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zoneName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: zoneColor,
                        ),
                      ),
                      Text(
                        zoneDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isUnlocked ? Icons.lock_open : Icons.lock,
                  color: isUnlocked ? Colors.green : Colors.red,
                  size: 32,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: metCount / totalCount,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: isUnlocked ? Colors.green : zoneColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$metCount/$totalCount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.green : zoneColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUnlocked ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUnlocked ? Icons.check_circle : Icons.cancel,
                    color: isUnlocked ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUnlocked ? 'UNLOCKED - Safe to Use' : 'LOCKED - Requirements Not Met',
                    style: TextStyle(
                      color: isUnlocked ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Requirements Checklist
            const Text(
              'Requirements:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...requirementsList.map((entry) {
              final met = entry.value as bool;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      met ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: met ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatRequirementText(entry.key),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
                              color: met ? Colors.black87 : Colors.grey[700],
                            ),
                          ),
                          if (!met) ...[
                            const SizedBox(height: 4),
                            Text(
                              _getRequirementTip(entry.key),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[700], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRequirementText(String key) {
    switch (key) {
      case 'aisri_score':
        return 'AISRI Score ≥ 70 (Power) or ≥ 75 (Speed)';
      case 'rom_score':
        return 'Range of Motion Score ≥ 75';
      case 'no_recent_injuries':
        return 'No injuries in the past 4 weeks';
      case 'training_weeks':
        return 'Minimum 8 weeks of consistent training in lower zones';
      case 'load_ratio':
        return 'Training load ratio ≤ 1.3 (safe training progression)';
      case 'all_pillars':
        return 'All 5 supporting pillars ≥ 75 (Strength, ROM, Balance, Mobility, Alignment)';
      case 'perfect_form':
        return 'Perfect running form verified through assessment';
      case 'extended_training':
        return 'Minimum 12 weeks of training including Power zone work';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getRequirementTip(String key) {
    switch (key) {
      case 'aisri_score':
        return 'Complete assessments and train consistently to improve your overall AISRI score';
      case 'rom_score':
        return 'Focus on ankle dorsiflexion and hip mobility exercises';
      case 'no_recent_injuries':
        return 'Allow full recovery before attempting high-intensity work';
      case 'training_weeks':
        return 'Build aerobic base through Foundation and Endurance zones';
      case 'load_ratio':
        return 'Increase weekly volume gradually (max 10% per week)';
      case 'all_pillars':
        return 'Complete strength, balance, and mobility assessments regularly';
      case 'perfect_form':
        return 'Work with a coach or use video analysis for form improvement';
      case 'extended_training':
        return 'Master Power zone work before progressing to Speed work';
      default:
        return 'Continue training to meet this requirement';
    }
  }
}
