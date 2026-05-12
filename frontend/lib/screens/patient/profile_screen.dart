import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curasync/config/theme.dart';
import 'package:curasync/providers/auth_provider.dart';
import 'package:curasync/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<dynamic> _recentVisits = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final res = await ApiService.getPatientProfile(token: auth.token!);
      if (!mounted) return;
      Map<String, dynamic>? profile;
      List<dynamic> history = [];
      if (res.containsKey('profile')) {
        profile = res['profile'];
        history = res['history'] ?? [];
      } else if (res.containsKey('data') && res['data'] != null) {
        profile = res['data']['profile'];
        history = res['data']['history'] ?? [];
      }
      setState(() {
        _profile = profile;
        _recentVisits = history.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    return RefreshIndicator(
      onRefresh: _fetchProfile,
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildRecentVisits(),
          const SizedBox(height: 24),
          _buildLogoutButton(),
          const SizedBox(height: 60),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('My Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, color: AppTheme.success, size: 8),
          SizedBox(width: 6),
          Text('Active', style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    ]);
  }

  Widget _buildProfileCard() {
    final name = _profile?['name'] ?? context.read<AuthProvider>().name ?? 'Patient';
    final email = _profile?['email'] ?? context.read<AuthProvider>().email ?? '';
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        // Avatar
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2)),
          child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(height: 16),
        const Text('PATIENT', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
      ]),
    );
  }

  Widget _buildStatsRow() {
    final age = _profile?['age'];
    final weight = _profile?['weight'];
    final totalVisits = _recentVisits.length;

    return Row(children: [
      Expanded(child: _statTile(Icons.cake_outlined, age != null ? '$age yrs' : '--', 'Age', AppTheme.accentBlue)),
      const SizedBox(width: 12),
      Expanded(child: _statTile(Icons.monitor_weight_outlined, weight != null ? '$weight kg' : '--', 'Weight', AppTheme.success)),
      const SizedBox(width: 12),
      Expanded(child: _statTile(Icons.event_note_outlined, '$totalVisits', 'Visits', AppTheme.warning)),
    ]);
  }

  Widget _statTile(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildRecentVisits() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recent Visits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        if (_recentVisits.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No visits yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14))))
        else
          ...List.generate(_recentVisits.length, (i) {
            final item = _recentVisits[i] as Map<String, dynamic>;
            return _visitRow(item, i < _recentVisits.length - 1);
          }),
      ]),
    );
  }

  Widget _visitRow(Map<String, dynamic> item, bool showDivider) {
    final doc = item['doctorId'];
    String name = 'Doctor', spec = 'Specialist';
    if (doc is Map<String, dynamic>) {
      name = doc['name'] ?? name;
      spec = doc['speciality'] ?? doc['specialty'] ?? spec;
    }
    final reason = item['reasonForVisit'] ?? '';
    final created = item['createdAt'] ?? '';
    String date = '';
    try {
      final d = DateTime.parse(created).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      date = '${m[d.month-1]} ${d.day}, ${d.year}';
    } catch (_) {}
    final status = (item['status'] ?? 'completed').toString().toUpperCase();
    final sc = AppTheme.specialtyColors[spec] ?? AppTheme.primaryBlue;

    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.person, color: sc, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text(reason.isNotEmpty ? reason : spec, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text(status, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ]),
        ])),
      if (showDivider) Divider(color: AppTheme.divider.withValues(alpha: 0.5), height: 1),
    ]);
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity, height: 56,
      child: OutlinedButton.icon(
        onPressed: () {
          context.read<AuthProvider>().logout();
          Navigator.pushReplacementNamed(context, '/login');
        },
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error, side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
