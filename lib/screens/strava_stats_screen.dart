import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'strava_oauth_screen.dart';

/// Displays Strava stats + PBs after OAuth completes.
/// Pops with a [StravaAuthResult] when the user taps "Let's Run!".
class StravaStatsScreen extends StatefulWidget {
  final StravaAuthResult result;
  final String apiUrl;

  const StravaStatsScreen({
    super.key,
    required this.result,
    required this.apiUrl,
  });

  @override
  State<StravaStatsScreen> createState() => _StravaStatsScreenState();
}

class _StravaStatsScreenState extends State<StravaStatsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  // ── Strava brand colour ──────────────────────────────────────────────────
  static const Color _stravaOrange = Color(0xFFFC4C02);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
          '${widget.apiUrl}/api/athlete-stats/${widget.result.stravaAthleteId}');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(resp.body) as Map<String, dynamic>;
        });
      } else {
        setState(() {
          _error = 'Could not load stats (${resp.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  // ── Format helpers ───────────────────────────────────────────────────────
  String _fmtTime(dynamic secs) {
    if (secs == null) return '—';
    final s = (secs as num).toInt();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final ss = s % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}:${ss.toString().padLeft(2, '0')}';
  }

  String _fmtPace(dynamic secPerKm) {
    if (secPerKm == null) return '—';
    final s = (secPerKm as num).toInt();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')} /km';
  }

  String _fmtDist(dynamic km) {
    if (km == null) return '—';
    return '${(km as num).toStringAsFixed(1)} km';
  }

  String _fmtNum(dynamic n) => n == null ? '—' : (n as num).toStringAsFixed(0);

  // ── Widgets ──────────────────────────────────────────────────────────────
  Widget _statCard(String label, String value, {IconData? icon}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            if (icon != null) Icon(icon, color: _stravaOrange, size: 20),
            if (icon != null) const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pbRow(String distance, dynamic secs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _stravaOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              distance,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            _fmtTime(secs),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final athlete = widget.result.athlete;
    final name = athlete['firstname'] != null
        ? '${athlete['firstname']} ${athlete['lastname'] ?? ''}'.trim()
        : widget.result.athlete['username'] ?? 'Athlete';
    final photoUrl = athlete['profile'] as String?;
    final isNew = widget.result.isNewUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _stravaOrange,
        foregroundColor: Colors.white,
        title: Text(isNew ? 'Welcome to SafeStride!' : 'Welcome Back!'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _stravaOrange))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red[400], size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStats,
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context, widget.result),
                        child: const Text('Skip & Continue'),
                      ),
                    ],
                  ),
                )
              : _buildStats(name, photoUrl, isNew),
      floatingActionButton: !_loading
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context, widget.result),
              backgroundColor: _stravaOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.directions_run),
              label: const Text("Let's Run!",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStats(String name, String? photoUrl, bool isNew) {
    final s = _stats!;
    final city = s['city'] as String?;
    final country = s['country'] as String?;
    final location =
        [city, country].where((e) => e != null && e.isNotEmpty).join(', ');

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          color: _stravaOrange,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white30,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, size: 36, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    if (location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 2),
                          Text(location,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isNew ? '🎉 New athlete' : '🔄 Returning athlete',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Scrollable content ───────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats grid
                const Text('Running Stats',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.95,
                  children: [
                    _statCard('Total Runs', _fmtNum(s['total_runs']),
                        icon: Icons.directions_run),
                    _statCard('Distance', _fmtDist(s['total_distance_km']),
                        icon: Icons.straighten),
                    _statCard(
                        'Time',
                        s['total_time_hours'] != null
                            ? '${(s['total_time_hours'] as num).toStringAsFixed(0)}h'
                            : '—',
                        icon: Icons.timer),
                    _statCard(
                        'Avg Pace',
                        _fmtPace(s['avg_pace_min_per_km'] != null
                            ? (s['avg_pace_min_per_km'] as num) * 60
                            : null),
                        icon: Icons.speed),
                    _statCard('Longest', _fmtDist(s['longest_run_km']),
                        icon: Icons.trending_up),
                    _statCard('Activities', _fmtNum(s['total_runs']),
                        icon: Icons.bar_chart),
                  ],
                ),

                const SizedBox(height: 20),

                // PBs
                const Text('Personal Bests',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _pbRow('5K', s['pb_5k']),
                        const Divider(height: 1),
                        _pbRow('10K', s['pb_10k']),
                        const Divider(height: 1),
                        _pbRow('Half Marathon', s['pb_half_marathon']),
                        const Divider(height: 1),
                        _pbRow('Marathon', s['pb_marathon']),
                      ],
                    ),
                  ),
                ),

                if (s['last_strava_sync'] != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Syncing activities in background…',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],

                const SizedBox(height: 80), // space for FAB
              ],
            ),
          ),
        ),
      ],
    );
  }
}
