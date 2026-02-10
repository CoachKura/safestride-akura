// lib/screens/injury_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/injury.dart';
import 'package:intl/intl.dart';

class InjuryDetailScreen extends StatefulWidget {
  final Injury? injury;
  final VoidCallback onSave;

  const InjuryDetailScreen({super.key, this.injury, required this.onSave});

  @override
  State<InjuryDetailScreen> createState() => _InjuryDetailScreenState();
}

class _InjuryDetailScreenState extends State<InjuryDetailScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _causedByController;
  late TextEditingController _treatmentController;
  late TextEditingController _notesController;
  
  String _selectedType = 'acute';
  String _selectedArea = 'left_knee';
  String _selectedStatus = 'active';
  int _severity = 5;
  int _painLevel = 5;
  int _recoveryPercentage = 0;
  DateTime _injuryDate = DateTime.now();
  DateTime? _expectedRecoveryDate;

  final List<String> _injuryTypes = ['acute', 'chronic', 'overuse', 'traumatic'];
  final List<String> _affectedAreas = [
    'left_ankle', 'right_ankle', 'left_knee', 'right_knee',
    'left_hip', 'right_hip', 'left_shin', 'right_shin',
    'left_foot', 'right_foot', 'left_calf', 'right_calf',
    'lower_back', 'upper_back', 'left_shoulder', 'right_shoulder',
    'left_achilles', 'right_achilles', 'left_hamstring', 'right_hamstring',
    'left_quad', 'right_quad', 'it_band', 'groin', 'other'
  ];
  final List<String> _statuses = ['active', 'recovering', 'healed', 'chronic'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.injury?.injuryName ?? '');
    _causedByController = TextEditingController(text: widget.injury?.causedBy ?? '');
    _treatmentController = TextEditingController(text: widget.injury?.treatmentPlan ?? '');
    _notesController = TextEditingController(text: widget.injury?.recoveryNotes ?? '');

    if (widget.injury != null) {
      _selectedType = widget.injury!.injuryType;
      _selectedArea = widget.injury!.affectedArea;
      _selectedStatus = widget.injury!.status;
      _severity = widget.injury!.severity;
      _painLevel = widget.injury!.currentPainLevel ?? 5;
      _recoveryPercentage = widget.injury!.recoveryPercentage;
      _injuryDate = widget.injury!.injuryDate;
      _expectedRecoveryDate = widget.injury!.expectedRecoveryDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _causedByController.dispose();
    _treatmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveInjury() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = {
        'user_id': userId,
        'injury_name': _nameController.text,
        'injury_type': _selectedType,
        'affected_area': _selectedArea,
        'severity': _severity,
        'current_pain_level': _painLevel,
        'status': _selectedStatus,
        'injury_date': _injuryDate.toIso8601String().split('T')[0],
        'expected_recovery_date': _expectedRecoveryDate?.toIso8601String().split('T')[0],
        'caused_by': _causedByController.text.isNotEmpty ? _causedByController.text : null,
        'treatment_plan': _treatmentController.text.isNotEmpty ? _treatmentController.text : null,
        'recovery_percentage': _recoveryPercentage,
        'recovery_notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      if (widget.injury != null) {
        await supabase
            .from('injuries')
            .update(data)
            .eq('id', widget.injury!.id);
      } else {
        await supabase.from('injuries').insert(data);
      }

      widget.onSave();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.injury != null ? 'Injury updated' : 'Injury added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.injury != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Injury' : 'Add Injury'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          TextButton(
            onPressed: _saveInjury,
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Injury Name*',
                hintText: 'e.g., Plantar Fasciitis',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Please enter injury name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedArea,
              decoration: const InputDecoration(
                labelText: 'Affected Area*',
                border: OutlineInputBorder(),
              ),
              items: _affectedAreas.map((area) {
                return DropdownMenuItem(
                  value: area,
                  child: Text(area.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedArea = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Injury Type*',
                border: OutlineInputBorder(),
              ),
              items: _injuryTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type[0].toUpperCase() + type.substring(1)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status*',
                border: OutlineInputBorder(),
              ),
              items: _statuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status[0].toUpperCase() + status.substring(1)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
            const SizedBox(height: 24),
            Text('Severity: $_severity/10', style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _severity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _severity.toString(),
              onChanged: (value) => setState(() => _severity = value.round()),
            ),
            const SizedBox(height: 16),
            Text('Current Pain Level: $_painLevel/10', style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _painLevel.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: _painLevel.toString(),
              onChanged: (value) => setState(() => _painLevel = value.round()),
            ),
            const SizedBox(height: 16),
            Text('Recovery: $_recoveryPercentage%', style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _recoveryPercentage.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '$_recoveryPercentage%',
              onChanged: (value) => setState(() => _recoveryPercentage = value.round()),
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('Injury Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_injuryDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _injuryDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _injuryDate = date);
              },
            ),
            ListTile(
              title: const Text('Expected Recovery Date'),
              subtitle: Text(_expectedRecoveryDate != null
                  ? DateFormat('MMM dd, yyyy').format(_expectedRecoveryDate!)
                  : 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expectedRecoveryDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _expectedRecoveryDate = date);
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _causedByController,
              decoration: const InputDecoration(
                labelText: 'Caused By',
                hintText: 'e.g., Increased mileage too quickly',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _treatmentController,
              decoration: const InputDecoration(
                labelText: 'Treatment Plan',
                hintText: 'Rest, ice, stretching...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Recovery Notes',
                hintText: 'Progress updates, symptoms...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
