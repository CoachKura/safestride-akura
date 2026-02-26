import 'dart:math' as math;
import 'package:flutter/material.dart';

class StravaTrainingPlanScreen extends StatefulWidget {
  final Map<String, dynamic> stats;

  const StravaTrainingPlanScreen({super.key, required this.stats});

  @override
  State<StravaTrainingPlanScreen> createState() =>
      _StravaTrainingPlanScreenState();
}

class _StravaTrainingPlanScreenState extends State<StravaTrainingPlanScreen> {
  static const Color _orange = Color(0xFFFC4C02);
  static const Color _dark = Color(0xFF1A1A2E);
  static const Color _card = Color(0xFF16213E);
  static const Color _green = Color(0xFF00D9A3);

  // ── State ──────────────────────────────────────────────────────────────────
  int _goalIndex = 0; // 0=5K, 1=10K, 2=Half, 3=Marathon
  int _weeks = 12;
  int? _expandedWeek;

  static const List<String> _goalLabels = [
    '5K',
    '10K',
    'Half Marathon',
    'Marathon'
  ];
  static const List<double> _goalDistKm = [5.0, 10.0, 21.097, 42.195];
  static const List<int> _goalPbKeys = [
    5000,
    10000,
    21097,
    42195
  ]; // metres labels
  static const List<String> _pbFieldKeys = [
    'pb_5k',
    'pb_10k',
    'pb_half_marathon',
    'pb_marathon'
  ];

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns current PB in seconds, or null.
  int? get _currentPb => widget.stats[_pbFieldKeys[_goalIndex]] as int?;

  /// 5K pace in sec/km (used to derive all training paces).
  double get _fiveKPaceSecPerKm {
    final pb5k = widget.stats['pb_5k'] as int?;
    if (pb5k != null) return pb5k / 5.0;
    // Estimate from avg pace if no 5K PB
    final avg = widget.stats['avg_pace_min_per_km'] as num?;
    if (avg != null) return avg * 60 * 0.85; // faster than avg
    return 360.0; // default 6:00/km
  }

  double get _easyPaceSecKm => _fiveKPaceSecPerKm + 75;
  double get _tempoPaceSecKm => _fiveKPaceSecPerKm + 15;
  double get _intervalPaceSecKm => math.max(_fiveKPaceSecPerKm - 5, 180);

  String _fmtPaceSec(double secPerKm) {
    final m = secPerKm ~/ 60;
    final s = (secPerKm % 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  String _fmtTime(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0)
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  /// Riegel target time for a new distance given existing PB.
  int? _riegelProject(double targetKm) {
    final pb5k = widget.stats['pb_5k'] as int?;
    if (pb5k == null) return null;
    return (pb5k * math.pow(targetKm / 5.0, 1.06)).round();
  }

  // ── Plan generation ─────────────────────────────────────────────────────
  static const Map<String, _PlanProfile> _profiles = {
    '5K': _PlanProfile(
        baseKm: 25,
        peakKm: 45,
        longRunPeak: 12,
        intervals: '6×400m',
        tempoKm: 4,
        easyKm: 6),
    '10K': _PlanProfile(
        baseKm: 35,
        peakKm: 55,
        longRunPeak: 18,
        intervals: '5×800m',
        tempoKm: 6,
        easyKm: 8),
    'Half Marathon': _PlanProfile(
        baseKm: 45,
        peakKm: 70,
        longRunPeak: 22,
        intervals: '4×1km',
        tempoKm: 8,
        easyKm: 10),
    'Marathon': _PlanProfile(
        baseKm: 55,
        peakKm: 90,
        longRunPeak: 35,
        intervals: '3×2km',
        tempoKm: 10,
        easyKm: 12),
  };

  List<_TrainingWeek> _buildPlan() {
    final label = _goalLabels[_goalIndex];
    final profile = _profiles[label]!;
    final weeks = <_TrainingWeek>[];

    for (int w = 1; w <= _weeks; w++) {
      final progress = (w - 1) / (_weeks - 1); // 0.0 → 1.0
      final isTaper = w > _weeks - 2;
      final taperMult = isTaper ? (w == _weeks ? 0.6 : 0.75) : 1.0;
      final vol =
          (profile.baseKm + (profile.peakKm - profile.baseKm) * progress) *
              taperMult;
      final longRun =
          (5.0 + (profile.longRunPeak - 5.0) * progress) * taperMult;
      final phase = isTaper
          ? 'Taper'
          : progress < 0.33
              ? 'Base'
              : progress < 0.66
                  ? 'Build'
                  : 'Peak';

      weeks.add(_TrainingWeek(
        weekNum: w,
        phase: phase,
        totalKm: vol.roundToDouble(),
        workouts: [
          _Workout('Mon', 'Rest', '', 0, WorkoutType.rest),
          _Workout('Tue', 'Intervals', profile.intervals,
              (vol * 0.15).round().toDouble(), WorkoutType.interval),
          _Workout('Wed', 'Easy Run', '${(vol * 0.2).round()} km easy',
              (vol * 0.2).round().toDouble(), WorkoutType.easy),
          _Workout(
              'Thu',
              'Tempo Run',
              '${isTaper ? (profile.tempoKm * taperMult).round() : profile.tempoKm} km @ tempo',
              (profile.tempoKm * (isTaper ? taperMult : 1)).roundToDouble(),
              WorkoutType.tempo),
          _Workout(
              'Fri', 'Rest / Cross', 'Stretch or cycle', 0, WorkoutType.rest),
          _Workout('Sat', 'Long Run', '${longRun.round()} km @ easy',
              longRun.roundToDouble(), WorkoutType.longRun),
          _Workout('Sun', 'Recovery', '${(vol * 0.1).round()} km easy jog',
              (vol * 0.1).round().toDouble(), WorkoutType.easy),
        ],
      ));
    }
    return weeks;
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final plan = _buildPlan();
    final targetTime = _riegelProject(_goalDistKm[_goalIndex]);
    final currentPb = _currentPb;

    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        title: const Text('Training Plan Generator'),
      ),
      body: Column(
        children: [
          // ── Settings panel ───────────────────────────────────────────────
          Container(
            color: _card,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Goal chips
                Row(
                  children: List.generate(
                    _goalLabels.length,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _goalIndex = i;
                            _expandedWeek = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _goalIndex == i
                                  ? _orange
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _goalLabels[i],
                              style: TextStyle(
                                color: _goalIndex == i
                                    ? Colors.white
                                    : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // PB + projected target row
                Row(
                  children: [
                    Expanded(
                      child: _infoBox(
                        'Current PB',
                        currentPb != null ? _fmtTime(currentPb) : 'No PB yet',
                        Icons.emoji_events,
                        _orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoBox(
                          'Projected Target',
                          targetTime != null
                              ? _fmtTime((targetTime * 0.97)
                                  .round()) // ~3% improvement
                              : '—',
                          Icons.flag,
                          _green),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Paces row
                Row(
                  children: [
                    Expanded(
                        child: _paceBox('Easy', _fmtPaceSec(_easyPaceSecKm),
                            Colors.blueAccent)),
                    const SizedBox(width: 6),
                    Expanded(
                        child: _paceBox('Tempo', _fmtPaceSec(_tempoPaceSecKm),
                            Colors.amber)),
                    const SizedBox(width: 6),
                    Expanded(
                        child: _paceBox('Interval',
                            _fmtPaceSec(_intervalPaceSecKm), _orange)),
                  ],
                ),

                const SizedBox(height: 14),

                // Duration toggle
                Row(
                  children: [
                    const Text('Plan Length:',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 10),
                    _durationBtn(8),
                    const SizedBox(width: 8),
                    _durationBtn(12),
                    const SizedBox(width: 8),
                    _durationBtn(16),
                  ],
                ),
              ],
            ),
          ),

          // ── Week list ────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: plan.length,
              itemBuilder: (ctx, i) => _weekCard(plan[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 10)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paceBox(String label, String pace, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(pace,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _durationBtn(int w) {
    final sel = _weeks == w;
    return GestureDetector(
      onTap: () => setState(() {
        _weeks = w;
        _expandedWeek = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? _orange : Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('$w wks',
            style: TextStyle(
                color: sel ? Colors.white : Colors.white54,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                fontSize: 12)),
      ),
    );
  }

  Widget _weekCard(_TrainingWeek week) {
    final isExpanded = _expandedWeek == week.weekNum;
    final phaseColor = _phaseColor(week.phase);

    return Card(
      color: _card,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: phaseColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(
                () => _expandedWeek = isExpanded ? null : week.weekNum),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: phaseColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: phaseColor),
                    ),
                    child: Center(
                      child: Text('${week.weekNum}',
                          style: TextStyle(
                              color: phaseColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Week ${week.weekNum}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text('${week.phase} · ${week.totalKm.round()} km',
                            style: TextStyle(color: phaseColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            ...week.workouts.map((w) => _workoutRow(w)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _workoutRow(_Workout w) {
    final color = _workoutColor(w.type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(w.day,
                style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          Container(
            width: 4,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.name,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                if (w.detail.isNotEmpty)
                  Text(w.detail,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (w.distKm > 0)
            Text('${w.distKm.round()} km',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Color _phaseColor(String phase) {
    switch (phase) {
      case 'Base':
        return Colors.blueAccent;
      case 'Build':
        return Colors.amber;
      case 'Peak':
        return _orange;
      case 'Taper':
        return _green;
      default:
        return Colors.white54;
    }
  }

  Color _workoutColor(WorkoutType t) {
    switch (t) {
      case WorkoutType.interval:
        return _orange;
      case WorkoutType.tempo:
        return Colors.amber;
      case WorkoutType.longRun:
        return Colors.purpleAccent;
      case WorkoutType.easy:
        return Colors.blueAccent;
      case WorkoutType.rest:
        return Colors.white30;
    }
  }
}

// ── Data classes ───────────────────────────────────────────────────────────────

class _PlanProfile {
  final double baseKm, peakKm, longRunPeak;
  final String intervals;
  final double tempoKm, easyKm;
  const _PlanProfile({
    required this.baseKm,
    required this.peakKm,
    required this.longRunPeak,
    required this.intervals,
    required this.tempoKm,
    required this.easyKm,
  });
}

class _TrainingWeek {
  final int weekNum;
  final String phase;
  final double totalKm;
  final List<_Workout> workouts;
  const _TrainingWeek({
    required this.weekNum,
    required this.phase,
    required this.totalKm,
    required this.workouts,
  });
}

enum WorkoutType { easy, tempo, interval, longRun, rest }

class _Workout {
  final String day, name, detail;
  final double distKm;
  final WorkoutType type;
  const _Workout(this.day, this.name, this.detail, this.distKm, this.type);
}
