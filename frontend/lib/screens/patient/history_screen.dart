import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curasync/config/theme.dart';
import 'package:curasync/providers/auth_provider.dart';
import 'package:curasync/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final res = await ApiService.getPatientProfile(token: auth.token!);
      if (!mounted) return;
      List<dynamic> history = [];
      if (res.containsKey('history')) {
        history = res['history'] ?? [];
      } else if (res.containsKey('data') && res['data'] != null) {
        history = res['data']['history'] ?? [];
      }
      setState(() { _history = history; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Could not load history'; _isLoading = false; });
    }
  }

  IconData _specialtyIcon(String s) {
    switch (s.toLowerCase()) {
      case 'cardiologist': return Icons.monitor_heart_outlined;
      case 'dermatologist': return Icons.spa_outlined;
      case 'pediatrician': return Icons.child_care_outlined;
      case 'orthopedic': return Icons.accessibility_new_rounded;
      default: return Icons.medical_services_outlined;
    }
  }

  Color _specColor(String s) => AppTheme.specialtyColors[s] ?? AppTheme.primaryBlue;

  Color _statusColor(String s) {
    switch (s) {
      case 'completed': return AppTheme.primaryBlue;
      case 'in-progress': return AppTheme.warning;
      case 'waiting': return AppTheme.success;
      case 'cancelled': return AppTheme.error;
      default: return AppTheme.textSecondary;
    }
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[d.month-1]} ${d.day.toString().padLeft(2,'0')}, ${d.year}';
    } catch (_) { return '--'; }
  }

  String _fmtTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
      return '${h.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) { return '--:--'; }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    if (_error != null) return _buildError();
    if (_history.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildError() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 56, color: AppTheme.textHint),
      const SizedBox(height: 16),
      Text(_error!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: _fetchHistory, icon: const Icon(Icons.refresh, size: 18), label: const Text('Retry'), style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48))),
    ])));

  Widget _buildEmpty() => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: SizedBox(height: MediaQuery.of(context).size.height * 0.7, child: Center(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 100, height: 100, decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.history_rounded, size: 48, color: AppTheme.primaryBlue)),
          const SizedBox(height: 28),
          const Text('No Appointments Yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          const Text('Your appointment history will appear here\nonce you book a doctor.', textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.6)),
        ])))));

  Widget _buildList() => RefreshIndicator(
    onRefresh: _fetchHistory,
    color: AppTheme.primaryBlue,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Appointment History', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          Text('${_history.length} visits', style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 24),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) => _buildCard(_history[i]),
        ),
        const SizedBox(height: 60),
      ])));

  Widget _buildCard(Map<String, dynamic> item) {
    final doc = item['doctorId'];
    String name = 'Unknown Doctor', spec = 'Specialist';
    if (doc is Map<String, dynamic>) {
      name = doc['name'] ?? name;
      spec = doc['speciality'] ?? doc['specialty'] ?? spec;
    }
    final reason = item['reasonForVisit'] ?? 'General Consultation';
    final status = item['status'] ?? 'completed';
    final created = item['createdAt'] ?? '';
    final sc = _specColor(spec);
    final stc = _statusColor(status);

    return Container(
      decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: sc.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
            child: Icon(_specialtyIcon(spec), color: sc, size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('$spec • $reason', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_fmtDate(created), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(_fmtTime(created), style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: stc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(status.toUpperCase(), style: TextStyle(color: stc, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
        ]),
      ]));
  }
}
