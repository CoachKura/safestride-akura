// Step Editor Screen - Edit individual workout steps with Garmin-style features
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/structured_workout.dart';

class StepEditorScreen extends StatefulWidget {
  final WorkoutStep? step; // null = create new, not null = edit

  const StepEditorScreen({
    super.key,
    this.step,
  });

  @override
  State<StepEditorScreen> createState() => _StepEditorScreenState();
}

class _StepEditorScreenState extends State<StepEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationValueController = TextEditingController();
  final _targetMinController = TextEditingController();
  final _targetMaxController = TextEditingController();
  final _notesController = TextEditingController();

  WorkoutStepType _stepType = WorkoutStepType.run;
  DurationType _durationType = DurationType.distance;
  IntensityType _intensityType = IntensityType.noTarget;
  int? _heartRateZone;
  int? _userAge;

  @override
  void initState() {
    super.initState();
    _loadUserAge();
    if (widget.step != null) {
      final step = widget.step!;
      _stepType = step.stepType;
      _durationType = step.durationType;
      _intensityType = step.intensityType;
      _heartRateZone = step.heartRateZone;

      if (step.durationValue != null) {
        _durationValueController.text = step.durationValue.toString();
      }
      if (step.targetMin != null) {
        _targetMinController.text = step.targetMin.toString();
      }
      if (step.targetMax != null) {
        _targetMaxController.text = step.targetMax.toString();
      }
      if (step.notes != null) {
        _notesController.text = step.notes!;
      }
    }
  }

  Future<void> _loadUserAge() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('athlete_profile')
          .select('date_of_birth')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['date_of_birth'] != null) {
        final dob = DateTime.parse(response['date_of_birth']);
        final age = DateTime.now().year - dob.year;
        setState(() => _userAge = age);
      }
    } catch (e) {
      // If error, _userAge remains null and we'll use default
    }
  }

  @override
  void dispose() {
    _durationValueController.dispose();
    _targetMinController.dispose();
    _targetMaxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveStep() {
    if (!_formKey.currentState!.validate()) return;

    // Validate duration value for required types
    if (_durationType != DurationType.lapPress &&
        _durationType != DurationType.open &&
        _durationValueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a duration value')),
      );
      return;
    }

    // Validate intensity targets for custom ranges
    if ((_intensityType == IntensityType.customHeartRate ||
            _intensityType == IntensityType.pace ||
            _intensityType == IntensityType.cadence ||
            _intensityType == IntensityType.customPower) &&
        (_targetMinController.text.trim().isEmpty ||
            _targetMaxController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter target min and max values')),
      );
      return;
    }

    // Parse values
    double? durationValue;
    if (_durationType != DurationType.lapPress &&
        _durationType != DurationType.open &&
        _durationValueController.text.trim().isNotEmpty) {
      durationValue = double.tryParse(_durationValueController.text.trim());
    }

    double? targetMin;
    double? targetMax;
    if (_intensityType == IntensityType.heartRateZone && _heartRateZone != null) {
      final zones = _getHRZoneRange(_heartRateZone!);
      targetMin = zones[0];
      targetMax = zones[1];
    } else if (_intensityType != IntensityType.noTarget &&
        _intensityType != IntensityType.heartRateZone &&
        _intensityType != IntensityType.powerZone) {
      targetMin = double.tryParse(_targetMinController.text.trim());
      targetMax = double.tryParse(_targetMaxController.text.trim());
    }

    // Create display strings
    String durationDisplay = _formatDuration(_durationType, durationValue);
    String targetDisplay = _formatTarget(
      _intensityType,
      _heartRateZone,
      targetMin,
      targetMax,
    );

    final step = WorkoutStep(
      id: widget.step?.id ?? const Uuid().v4(),
      stepType: _stepType,
      order: widget.step?.order ?? 0,
      durationType: _durationType,
      durationValue: durationValue,
      durationDisplay: durationDisplay,
      intensityType: _intensityType,
      targetMin: targetMin,
      targetMax: targetMax,
      heartRateZone: _heartRateZone,
      targetDisplay: targetDisplay,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      audioNote: null, // Future feature
    );

    Navigator.of(context).pop(step);
  }

  String _formatDuration(DurationType type, double? value) {
    switch (type) {
      case DurationType.distance:
        return value != null ? '${value.toStringAsFixed(2)} km' : '0.00 km';
      case DurationType.time:
        if (value == null) return '00:00:00';
        final hours = (value / 3600).floor();
        final minutes = ((value % 3600) / 60).floor();
        final seconds = (value % 60).floor();
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      case DurationType.lapPress:
        return 'Lap Button Press';
      case DurationType.calories:
        return value != null ? '${value.toStringAsFixed(0)} kcal' : '0 kcal';
      case DurationType.heartRate:
        return value != null ? 'Until ${value.toStringAsFixed(0)} bpm' : 'Until target HR';
      case DurationType.open:
        return 'Open (No Limit)';
    }
  }

  String _formatTarget(
      IntensityType type, int? hrZone, double? min, double? max) {
    switch (type) {
      case IntensityType.noTarget:
        return 'No Target';
      case IntensityType.pace:
        if (min != null && max != null) {
          return 'Pace ${min.toStringAsFixed(2)}-${max.toStringAsFixed(2)} min/km';
        }
        return 'Pace Target';
      case IntensityType.cadence:
        if (min != null && max != null) {
          return 'Cadence ${min.toStringAsFixed(0)}-${max.toStringAsFixed(0)} spm';
        }
        return 'Cadence Target';
      case IntensityType.heartRateZone:
        if (hrZone != null) {
          final range = _getHRZoneRange(hrZone);
          final zoneName = _getZoneName(hrZone);
          return '$zoneName (${range[0].toStringAsFixed(0)}-${range[1].toStringAsFixed(0)} bpm)';
        }
        return 'HR Zone';
      case IntensityType.customHeartRate:
        if (min != null && max != null) {
          return 'HR ${min.toStringAsFixed(0)}-${max.toStringAsFixed(0)} bpm';
        }
        return 'Custom HR';
      case IntensityType.powerZone:
        return 'Power Zone ${hrZone ?? 1}';
      case IntensityType.customPower:
        if (min != null && max != null) {
          return 'Power ${min.toStringAsFixed(0)}-${max.toStringAsFixed(0)} W';
        }
        return 'Custom Power';
    }
  }

  // Calculate Max HR using: Max HR = 208 - (0.7 × Age)
  // For 40-year-old: 208 - (0.7 × 40) = 208 - 28 = 180 bpm
  int _getMaxHR() {
    // TODO: Get actual user age from profile
    // For now, using 40 years old as default (Max HR = 180)
    const age = 40;
    return (208 - (0.7 * age)).round();
  }

  String _getZoneName(int zone) {
    switch (zone) {
      case 1:
        return 'Zone AR (Active Recovery)';
      case 2:
        return 'Zone F (Foundation)';
      case 3:
        return 'Zone EN (Endurance)';
      case 4:
        return 'Zone TH (Threshold ⭐)';
      case 5:
        return 'Zone P (Power)';
      case 6:
        return 'Zone SP (Speed)';
      default:
        return 'Zone $zone';
    }
  }

  String _getZonePurpose(int zone) {
    switch (zone) {
      case 1:
        return 'Recovery, Warm-up, Cool-down';
      case 2:
        return 'Aerobic Base, Fat Burning, Stamina';
      case 3:
        return 'Aerobic Fitness, Improved Oxygen Efficiency';
      case 4:
        return 'Lactate Threshold, Anaerobic Capacity, Speed Endurance';
      case 5:
        return 'Max Oxygen Uptake (VO2 Max), Peak Performance';
      case 6:
        return 'Anaerobic Power, Sprinting, Short Bursts';
      default:
        return '';
    }
  }

  List<double> _getHRZoneRange(int zone) {
    // 6 AISRI Training Zones based on Max HR percentage
    // Max HR = 208 - (0.7 × Age)
    final maxHR = _getMaxHR().toDouble();
    
    switch (zone) {
      case 1: // Zone AR: 50-60% Max HR
        return [(maxHR * 0.50), (maxHR * 0.60)];
      case 2: // Zone F: 60-70% Max HR
        return [(maxHR * 0.60), (maxHR * 0.70)];
      case 3: // Zone EN: 70-80% Max HR
        return [(maxHR * 0.70), (maxHR * 0.80)];
      case 4: // Zone TH (CORE): 80-87% Max HR
        return [(maxHR * 0.80), (maxHR * 0.87)];
      case 5: // Zone P: 87-95% Max HR
        return [(maxHR * 0.87), (maxHR * 0.95)];
      case 6: // Zone SP: 95-100% Max HR
        return [(maxHR * 0.95), (maxHR * 1.00)];
      default:
        return [(maxHR * 0.50), (maxHR * 0.60)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.step == null ? 'Add Step' : 'Edit Step'),
        actions: [
          TextButton(
            onPressed: _saveStep,
            child: const Text('DONE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Step Type Section
            _buildSectionTitle('Step Type'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<WorkoutStepType>(
                  initialValue: _stepType,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  items: WorkoutStepType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_getStepTypeDisplay(type)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _stepType = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Duration Section
            _buildSectionTitle('Duration'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Duration Type Dropdown
                    DropdownButtonFormField<DurationType>(
                      initialValue: _durationType,
                      decoration: const InputDecoration(
                        labelText: 'Duration Type',
                        prefixIcon: Icon(Icons.timer),
                      ),
                      items: DurationType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_getDurationTypeDisplay(type)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _durationType = value;
                            _durationValueController.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Duration Value Input
                    if (_durationType == DurationType.distance)
                      TextFormField(
                        controller: _durationValueController,
                        decoration: const InputDecoration(
                          labelText: 'Distance (km)',
                          hintText: '1.00',
                          suffixText: 'km',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      )
                    else if (_durationType == DurationType.time)
                      TextFormField(
                        controller: _durationValueController,
                        decoration: const InputDecoration(
                          labelText: 'Time (minutes)',
                          hintText: '30',
                          suffixText: 'min',
                          helperText: 'Will be converted to hh:mm:ss format',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) {
                          // Convert minutes to seconds
                          final minutes = double.tryParse(value);
                          if (minutes != null) {
                            _durationValueController.text = (minutes * 60).toString();
                            _durationValueController.selection = TextSelection.fromPosition(
                              TextPosition(offset: value.length),
                            );
                          }
                        },
                      )
                    else if (_durationType == DurationType.calories)
                      TextFormField(
                        controller: _durationValueController,
                        decoration: const InputDecoration(
                          labelText: 'Calories',
                          hintText: '300',
                          suffixText: 'kcal',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      )
                    else if (_durationType == DurationType.heartRate)
                      TextFormField(
                        controller: _durationValueController,
                        decoration: const InputDecoration(
                          labelText: 'Target Heart Rate',
                          hintText: '150',
                          suffixText: 'bpm',
                          helperText: 'Continue until HR reaches this value',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      )
                    else if (_durationType == DurationType.lapPress)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.touch_app, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Step will continue until you press the lap button',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_durationType == DurationType.open)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.all_inclusive, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Step has no duration limit',
                                style: TextStyle(color: Colors.green[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Intensity Target Section
            _buildSectionTitle('Intensity Target'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intensity Type Dropdown
                    DropdownButtonFormField<IntensityType>(
                      initialValue: _intensityType,
                      decoration: const InputDecoration(
                        labelText: 'Target Type',
                        prefixIcon: Icon(Icons.favorite),
                      ),
                      items: IntensityType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_getIntensityTypeDisplay(type)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _intensityType = value;
                            _heartRateZone = null;
                            _targetMinController.clear();
                            _targetMaxController.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Heart Rate Zone Selector
                    if (_intensityType == IntensityType.heartRateZone)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Select AISRI Training Zone:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(Max HR: ${_getMaxHR()} bpm)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(6, (index) {
                            final zone = index + 1;
                            final range = _getHRZoneRange(zone);
                            final zoneName = _getZoneName(zone);
                            final purpose = _getZonePurpose(zone);
                            
                            Color zoneColor;
                            switch (zone) {
                              case 1:
                                zoneColor = Colors.lightBlue.shade300;
                                break;
                              case 2:
                                zoneColor = Colors.blue;
                                break;
                              case 3:
                                zoneColor = Colors.teal;
                                break;
                              case 4:
                                zoneColor = Colors.orange; // CORE ZONE
                                break;
                              case 5:
                                zoneColor = Colors.red.shade400;
                                break;
                              case 6:
                                zoneColor = Colors.red.shade700;
                                break;
                              default:
                                zoneColor = Colors.grey;
                            }
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: _heartRateZone == zone
                                  ? zoneColor.withOpacity(0.1)
                                  : null,
                              child: RadioListTile<int>(
                                title: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: zoneColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        zoneName,
                                        style: TextStyle(
                                          fontWeight: zone == 4
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${range[0].toStringAsFixed(0)}-${range[1].toStringAsFixed(0)} bpm',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      purpose,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                value: zone,
                                groupValue: _heartRateZone,
                                onChanged: (value) {
                                  setState(() => _heartRateZone = value);
                                },
                              ),
                            );
                          }),
                        ],
                      )
                    // Custom Heart Rate Range
                    else if (_intensityType == IntensityType.customHeartRate)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _targetMinController,
                              decoration: const InputDecoration(
                                labelText: 'Min',
                                suffixText: 'bpm',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _targetMaxController,
                              decoration: const InputDecoration(
                                labelText: 'Max',
                                suffixText: 'bpm',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      )
                    // Pace Range
                    else if (_intensityType == IntensityType.pace)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _targetMinController,
                              decoration: const InputDecoration(
                                labelText: 'Min Pace',
                                suffixText: 'min/km',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _targetMaxController,
                              decoration: const InputDecoration(
                                labelText: 'Max Pace',
                                suffixText: 'min/km',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                            ),
                          ),
                        ],
                      )
                    // Cadence Range
                    else if (_intensityType == IntensityType.cadence)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _targetMinController,
                              decoration: const InputDecoration(
                                labelText: 'Min Cadence',
                                suffixText: 'spm',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _targetMaxController,
                              decoration: const InputDecoration(
                                labelText: 'Max Cadence',
                                suffixText: 'spm',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      )
                    // Custom Power Range
                    else if (_intensityType == IntensityType.customPower)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _targetMinController,
                              decoration: const InputDecoration(
                                labelText: 'Min Power',
                                suffixText: 'W',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _targetMaxController,
                              decoration: const InputDecoration(
                                labelText: 'Max Power',
                                suffixText: 'W',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      )
                    // No Target
                    else if (_intensityType == IntensityType.noTarget)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.remove_circle_outline, color: Colors.grey),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No intensity target for this step',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notes Section
            _buildSectionTitle('Notes (Optional)'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Add notes about this step...',
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getStepTypeDisplay(WorkoutStepType type) {
    switch (type) {
      case WorkoutStepType.warmUp:
        return 'Warm Up';
      case WorkoutStepType.run:
        return 'Run';
      case WorkoutStepType.recovery:
        return 'Recovery';
      case WorkoutStepType.rest:
        return 'Rest';
      case WorkoutStepType.coolDown:
        return 'Cool Down';
      case WorkoutStepType.repeat:
        return 'Repeat';
      case WorkoutStepType.other:
        return 'Other';
    }
  }

  String _getDurationTypeDisplay(DurationType type) {
    switch (type) {
      case DurationType.distance:
        return 'Distance';
      case DurationType.time:
        return 'Time';
      case DurationType.lapPress:
        return 'Lap Button Press';
      case DurationType.calories:
        return 'Calories';
      case DurationType.heartRate:
        return 'Heart Rate';
      case DurationType.open:
        return 'Open (No Limit)';
    }
  }

  String _getIntensityTypeDisplay(IntensityType type) {
    switch (type) {
      case IntensityType.noTarget:
        return 'No Target';
      case IntensityType.pace:
        return 'Pace';
      case IntensityType.cadence:
        return 'Cadence';
      case IntensityType.heartRateZone:
        return 'AISRI Training Zones (6 zones)';
      case IntensityType.customHeartRate:
        return 'Custom Heart Rate';
      case IntensityType.powerZone:
        return 'Power Zone';
      case IntensityType.customPower:
        return 'Custom Power';
    }
  }
}
