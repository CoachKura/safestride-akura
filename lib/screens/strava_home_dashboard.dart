import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/strava_oauth_screen.dart';
import '../screens/strava_training_plan_screen.dart';
import '../services/strava_session_service.dart';

class StravaHomeDashboard extends StatefulWidget {
  /// Pass a session directly, or leave null to load from SharedPreferences.
  final StravaAuthResult? session;

  const StravaHomeDashboard({super.key, this.session});

  @override
  State<StravaHomeDashboard> createState() => _StravaHomeDashboardState();
}

class _StravaHomeDashboardState extends State<StravaHomeDashboard> {
  StravaAuthResult? _session;
  Map<String, dynamic>? _stats;
  bool _loading = true;
  bool _syncing = false;

  static const Color _orange = Color(0xFFFC4C02);
  static const Color _dark = Color(0xFF1A1A2E);
  static const Color _card = Color(0xFF16213E);
  static const Color _accent = Color(0xFF00D9A3);

  static String get _apiUrl =>
      dotenv.env['SAFESTRIDE_STRAVA_API_URL'] ?? 'https://api.akura.in';

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    if (widget.session != null) {
      _session = widget.session;
      _loadStats();
    } else {
      final saved = await StravaSessionService.load();
      if (saved != null) {
        _session = saved;
        _loadStats();
      } else {
        // No Strava session - show connect prompt (don't redirect to login anymore)
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadStats({bool silent = false}) async {
    if (_session == null) {
      setState(() => _loading = false);
      return;
    }
    if (!silent) setState(() => _loading = true);
    try {
      final resp = await http.get(
        Uri.parse(
            '$_apiUrl/api/athlete-stats/${_session?.stravaAthleteId ?? ""}'),
      );
      if (resp.statusCode == 200 && mounted) {
        setState(() => _stats = jsonDecode(resp.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    if (mounted)
      setState(() {
        _loading = false;
        _syncing = false;
      });
  }

  Future<void> _syncActivities() async {
    if (_session == null) return;
    setState(() => _syncing = true);
    try {
      await http.post(
        Uri.parse('$_apiUrl/api/strava-sync-activities'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'strava_athlete_id': _session!.stravaAthleteId,
          'access_token': _session!.accessToken,
        }),
      );
      await _loadStats(silent: true);
    } catch (_) {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Sign out and return to login?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: _orange)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StravaSessionService.clear();
      await Supabase.instance.client.auth.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ── Format helpers ────────────────────────────────────────────────────────
  String _fmtTime(dynamic secs) {
    if (secs == null) return '—';
    final s = (secs as num).toInt();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final ss = s % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}:${ss.toString().padLeft(2, '0')}';
  }

  String _fmtPace(dynamic minPerKm) {
    if (minPerKm == null) return '—';
    final total = (minPerKm as num).toDouble();
    final m = total.floor();
    final s = ((total - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  // ── Widgets ───────────────────────────────────────────────────────────────
  Widget _statTile(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: _orange, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _pbChip(String dist, dynamic secs) {
    final hasValue = secs != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasValue ? _orange.withValues(alpha: 0.15) : Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: hasValue ? _orange.withValues(alpha: 0.4) : Colors.white12),
      ),
      child: Column(
        children: [
          Text(dist,
              style: TextStyle(
                  color: hasValue ? _orange : Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(height: 4),
          Text(_fmtTime(secs),
              style: TextStyle(
                  color: hasValue ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _quickAction(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If loading, show loading indicator
    if (_loading) {
      return const Scaffold(
        backgroundColor: _dark,
        body: Center(
          child: CircularProgressIndicator(color: _orange),
        ),
      );
    }

    // If no Strava session, show connect prompt
    if (_session == null) {
      return Scaffold(
        backgroundColor: _dark,
        appBar: AppBar(
          backgroundColor: _orange,
          title: const Text('SafeStride Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Sign Out',
              onPressed: _signOut,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_run, size: 80, color: _orange),
                const SizedBox(height: 24),
                const Text(
                  'Connect with Strava',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Link your Strava account to access training analytics, AISRI assessment, and personalized coaching.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<StravaAuthResult>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StravaOAuthScreen()),
                    );
                    if (result != null && mounted) {
                      await StravaSessionService.save(result);
                      setState(() {
                        _session = result;
                        _loading = true;
                      });
                      _loadStats();
                    }
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Connect Strava'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final athlete = _session?.athlete ?? {};
    final name = [athlete['firstname'], athlete['lastname']]
        .where((e) => e != null && (e as String).isNotEmpty)
        .join(' ');
    final photoUrl = athlete['profile'] as String?;
    final city = _stats?['city'] as String?;
    final country = _stats?['country'] as String?;
    final location =
        [city, country].where((e) => e != null && e!.isNotEmpty).join(', ');

    return Scaffold(
      backgroundColor: _dark,
      body: RefreshIndicator(
        onRefresh: () => _loadStats(),
        color: _orange,
        child: CustomScrollView(
          slivers: [
            // ── Hero header ────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: _orange,
              actions: [
                if (_syncing)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.sync, color: Colors.white),
                    tooltip: 'Sync Activities',
                    onPressed: _syncActivities,
                  ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Sign Out',
                  onPressed: _signOut,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFC4C02), Color(0xFFFF7043)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white30,
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? const Icon(Icons.person,
                                    size: 42, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty ? 'Athlete' : name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (location.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.white70, size: 13),
                                      const SizedBox(width: 2),
                                      Text(location,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('🔴 Strava Connected',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            _loading
                ? const SliverFillRemaining(
                    child: Center(
                        child: CircularProgressIndicator(color: _orange)))
                : SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Quick actions ─────────────────────────────────
                        const Text('Quick Actions',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: [
                            _quickAction(
                                'Training\nPlan', Icons.calendar_today, _orange,
                                () {
                              Navigator.pushNamed(context, '/calendar');
                            }),
                            _quickAction(
                                'History', Icons.bar_chart, Colors.purpleAccent,
                                () {
                              Navigator.pushNamed(context, '/run-history');
                            }),
                            _quickAction('Profile', Icons.person_outline,
                                Colors.blueAccent, () {
                              Navigator.pushNamed(context, '/profile');
                            }),
                            _quickAction('Analytics', Icons.analytics_outlined,
                                Colors.teal, () {
                              Navigator.pushNamed(context, '/analytics');
                            }),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Stats grid ────────────────────────────────────
                        const Text('Running Stats',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.9,
                          children: [
                            _statTile(
                                'Total Runs',
                                '${_stats?['total_runs'] ?? '—'}',
                                Icons.directions_run),
                            _statTile(
                                'Distance',
                                _stats?['total_distance_km'] != null
                                    ? '${(_stats!['total_distance_km'] as num).toStringAsFixed(1)} km'
                                    : '—',
                                Icons.straighten),
                            _statTile(
                                'Total Time',
                                _stats?['total_time_hours'] != null
                                    ? '${(_stats!['total_time_hours'] as num).toStringAsFixed(0)}h'
                                    : '—',
                                Icons.timer),
                            _statTile(
                                'Avg Pace',
                                _fmtPace(_stats?['avg_pace_min_per_km']),
                                Icons.speed),
                            _statTile(
                                'Longest',
                                _stats?['longest_run_km'] != null
                                    ? '${(_stats!['longest_run_km'] as num).toStringAsFixed(1)} km'
                                    : '—',
                                Icons.trending_up),
                            _statTile(
                                'Activities',
                                '${_stats?['total_runs'] ?? '—'}',
                                Icons.bar_chart),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── PBs ───────────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Personal Bests',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            if (_stats != null)
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StravaTrainingPlanScreen(
                                        stats: _stats!,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward,
                                    size: 14, color: _orange),
                                label: const Text('Make a Plan',
                                    style: TextStyle(
                                        color: _orange, fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.2,
                          children: [
                            _pbChip('5K', _stats?['pb_5k']),
                            _pbChip('10K', _stats?['pb_10k']),
                            _pbChip(
                                'Half Marathon', _stats?['pb_half_marathon']),
                            _pbChip('Marathon', _stats?['pb_marathon']),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ── Analytics link ───────────────────────────
                        OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/analytics'),
                          icon: const Icon(Icons.analytics_outlined,
                              color: _accent),
                          label: const Text('View Analytics Dashboard',
                              style: TextStyle(color: _accent)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _accent),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),

                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
