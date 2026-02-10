// lib/screens/injuries_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/injury.dart';
import 'injury_detail_screen.dart';

class InjuriesScreen extends StatefulWidget {
  const InjuriesScreen({super.key});

  @override
  State<InjuriesScreen> createState() => _InjuriesScreenState();
}

class _InjuriesScreenState extends State<InjuriesScreen> {
  final supabase = Supabase.instance.client;
  List<Injury> activeInjuries = [];
  List<Injury> healedInjuries = [];
  bool isLoading = true;
  bool showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _loadInjuries();
  }

  Future<void> _loadInjuries() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('injuries')
          .select()
          .eq('user_id', userId)
          .order('injury_date', ascending: false);

      final allInjuries = (response as List)
          .map((json) => Injury.fromJson(json))
          .toList();

      setState(() {
        activeInjuries = allInjuries.where((i) => i.isActive).toList();
        healedInjuries = allInjuries.where((i) => !i.isActive).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading injuries: $e')),
        );
      }
    }
  }

  void _showAddInjuryDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InjuryDetailScreen(
          onSave: () {
            _loadInjuries();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Injury Tracking'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: Icon(showActiveOnly ? Icons.history : Icons.warning_amber),
            onPressed: () {
              setState(() => showActiveOnly = !showActiveOnly);
            },
            tooltip: showActiveOnly ? 'Show All' : 'Show Active Only',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddInjuryDialog,
        backgroundColor: const Color(0xFFF44336),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    final injuries = showActiveOnly ? activeInjuries : [...activeInjuries, ...healedInjuries];

    if (injuries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showActiveOnly ? Icons.favorite : Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              showActiveOnly ? 'No active injuries' : 'No injuries recorded',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (showActiveOnly) ...[
              const SizedBox(height: 8),
              const Text(
                'Keep up the great work!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        if (activeInjuries.isNotEmpty) _buildSummaryCard(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: injuries.length,
            itemBuilder: (context, index) => _buildInjuryCard(injuries[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF44336), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Active Injuries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total',
                activeInjuries.length.toString(),
                Icons.warning_amber,
              ),
              _buildSummaryItem(
                'Recovering',
                activeInjuries.where((i) => i.status == 'recovering').length.toString(),
                Icons.trending_up,
              ),
              _buildSummaryItem(
                'Avg Recovery',
                '${activeInjuries.map((i) => i.recoveryPercentage).reduce((a, b) => a + b) ~/ activeInjuries.length}%',
                Icons.healing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInjuryCard(Injury injury) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InjuryDetailScreen(
              injury: injury,
              onSave: _loadInjuries,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(int.parse(injury.statusColor.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      injury.injuryName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(int.parse(injury.severityColor.replaceFirst('#', '0xFF')))
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      injury.severityLabel,
                      style: TextStyle(
                        color: Color(int.parse(injury.severityColor.replaceFirst('#', '0xFF'))),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                injury.affectedAreaDisplay,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Injured ${injury.daysSinceInjury} days ago',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (injury.isActive) ...[
                    Text(
                      '${injury.recoveryPercentage}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('recovered', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
              if (injury.isActive && injury.recoveryPercentage > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: injury.recoveryPercentage / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(int.parse(injury.statusColor.replaceFirst('#', '0xFF'))),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
