// lib/screens/body_measurements_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/body_measurement.dart';
import 'package:intl/intl.dart';

class BodyMeasurementsScreen extends StatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  final supabase = Supabase.instance.client;
  List<BodyMeasurement> measurements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('body_measurements')
          .select()
          .eq('user_id', userId)
          .order('measurement_date', ascending: false)
          .limit(20);

      setState(() {
        measurements = (response as List)
            .map((json) => BodyMeasurement.fromJson(json))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading measurements: $e')),
        );
      }
    }
  }

  void _showAddMeasurementDialog() {
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Measurement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final weight = double.tryParse(weightController.text);
              final height = int.tryParse(heightController.text);

              if (weight == null || height == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid values')),
                );
                return;
              }

              await _addMeasurement(weight, height, selectedDate);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMeasurement(double weight, int height, DateTime date) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('body_measurements').insert({
        'user_id': userId,
        'weight_kg': weight,
        'height_cm': height,
        'measurement_date': date.toIso8601String().split('T')[0],
        'measured_by': 'manual',
      });

      await _loadMeasurements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Measurement added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding measurement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Measurements'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : measurements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monitor_weight_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No measurements yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddMeasurementDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Measurement'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildProgressSummary(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: measurements.length,
                        itemBuilder: (context, index) =>
                            _buildMeasurementCard(measurements[index]),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: measurements.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddMeasurementDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProgressSummary() {
    if (measurements.length < 2) {
      return const SizedBox.shrink();
    }

    final current = measurements.first;
    final start = measurements.last;
    final weightChange = current.weightKg - start.weightKg;


    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(int.parse(current.bmiCategoryColor.replaceFirst('#', '0xFF'))), Colors.black87],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Progress Summary',
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
                'Weight Change',
                '${weightChange > 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg',
                Icons.trending_flat,
              ),
              _buildSummaryItem(
                'Current BMI',
                current.formattedBMI,
                Icons.insights,
              ),
              _buildSummaryItem(
                'Category',
                current.bmiCategoryDisplay,
                Icons.category,
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
            fontSize: 16,
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

  Widget _buildMeasurementCard(BodyMeasurement measurement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(measurement.measurementDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(int.parse(measurement.bmiCategoryColor.replaceFirst('#', '0xFF')))
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    measurement.bmiCategoryDisplay,
                    style: TextStyle(
                      color: Color(int.parse(measurement.bmiCategoryColor.replaceFirst('#', '0xFF'))),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Weight',
                    measurement.formattedWeight,
                    Icons.monitor_weight,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Height',
                    measurement.formattedHeight,
                    Icons.height,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'BMI',
                    measurement.formattedBMI,
                    Icons.insights,
                  ),
                ),
              ],
            ),
            if (measurement.notes != null) ...[
              const SizedBox(height: 12),
              Text(
                measurement.notes!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
