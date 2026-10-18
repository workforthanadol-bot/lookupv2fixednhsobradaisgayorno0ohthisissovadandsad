import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../database/db_helper.dart';
import '../database/nhso_db_helper.dart';
import '../models/candidate.dart';

class CombinedSearchScreen extends StatefulWidget {
  const CombinedSearchScreen({super.key});

  @override
  State<CombinedSearchScreen> createState() => _CombinedSearchScreenState();
}

class _CombinedSearchScreenState extends State<CombinedSearchScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  List<Candidate> _examResults = [];
  List<Map<String, dynamic>> _nhsoResults = [];
  bool _searched = false;

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; _searched = false; });

    try {
      // Determine if it looks like a citizen ID (13 digits)
      final isCid = RegExp(r'^\d{13}$').hasMatch(q);

      final examFuture = DbHelper.instance.search(query: q, limit: 100);
      final nhsoFuture = NhsoDbHelper.search(
        name: isCid ? null : q,
        citizenId: isCid ? q : null,
        limit: 100,
      );

      final results = await Future.wait([examFuture, nhsoFuture]);
      if (mounted) {
        setState(() {
          _examResults = results[0] as List<Candidate>;
          _nhsoResults = results[1] as List<Map<String, dynamic>>;
          _loading = false;
          _searched = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'ค้นหาผิดพลาด: $e'; _loading = false; });
    }
  }

  void _clear() {
    _ctrl.clear();
    setState(() {
      _examResults = [];
      _nhsoResults = [];
      _searched = false;
      _error = null;
    });
  }

  int get _total => _examResults.length + _nhsoResults.length;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นรวม'),
        actions: [
          if (_searched)
            IconButton(icon: const Icon(Icons.clear_all), onPressed: _clear),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : !_searched
                        ? _buildHint()
                        : _total == 0
                            ? _buildNoResult()
                            : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                hintText: 'ชื่อ / นามสกุล / เลขบัตรประชาชน',
                prefixIcon: Icon(Icons.manage_search),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _search,
            child: const Text('ค้นหา'),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search, size: 60, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('ค้นทั้งข้อมูลสอบ และ สปสช พร้อมกัน',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          SizedBox(height: 4),
          Text('พิมพ์ชื่อ นามสกุล หรือเลขบัตร 13 หลัก',
              style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
      ),
    );
  }

  Widget _buildNoResult() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 56, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('ไม่พบข้อมูลในทั้งสองฐาน',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary chip row
        Wrap(
          spacing: 8,
          children: [
            _chip('รวม $_total รายการ', AppTheme.primaryColor),
            if (_examResults.isNotEmpty)
              _chip('ข้อมูลสอบ ${_examResults.length}', const Color(0xFF1565C0)),
            if (_nhsoResults.isNotEmpty)
              _chip('สปสช ${_nhsoResults.length}', const Color(0xFF2E7D32)),
          ],
        ),
        const SizedBox(height: 12),

        // Exam results section
        if (_examResults.isNotEmpty) ...[
          _sectionHeader('📋 ข้อมูลผู้สมัครสอบ', const Color(0xFF1565C0)),
          const SizedBox(height: 6),
          ..._examResults.map((c) => _ExamCard(candidate: c)),
          const SizedBox(height: 16),
        ],

        // NHSO results section
        if (_nhsoResults.isNotEmpty) ...[
          _sectionHeader('🏥 ข้อมูล สปสช', const Color(0xFF2E7D32)),
          const SizedBox(height: 6),
          ..._nhsoResults.map((r) {
            final out = NhsoDbHelper.buildOutput(r);
            return _NhsoMiniCard(data: out);
          }),
        ],
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Chip(
      label: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _sectionHeader(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Exam result card (compact) ──────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  final Candidate candidate;
  const _ExamCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_ind,
                color: Color(0xFF1565C0), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(candidate.fullName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text('เลขที่สมัคร: ${candidate.examId}  |  ${candidate.province}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                if (candidate.status.isNotEmpty)
                  Text('สถานะ: ${candidate.status}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── NHSO result card (collapsible) ──────────────────────────────────────────

class _NhsoMiniCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _NhsoMiniCard({required this.data});

  @override
  State<_NhsoMiniCard> createState() => _NhsoMiniCardState();
}

class _NhsoMiniCardState extends State<_NhsoMiniCard> {
  bool _expanded = false;

  String get _fullName {
    final s1 = widget.data['ส่วนที่ ๑: ข้อมูลพื้นฐานบุคคล'] as Map?;
    return s1?['ชื่อ-นามสกุล']?.toString() ?? '-';
  }

  String get _cid {
    final s1 = widget.data['ส่วนที่ ๑: ข้อมูลพื้นฐานบุคคล'] as Map?;
    return s1?['เลขประจำตัวประชาชน']?.toString() ?? '-';
  }

  String get _hosp {
    final s4 = widget.data['ส่วนที่ ๔: DOPA / สปสช'] as Map?;
    return s4?['รพ.หลัก']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.health_and_safety,
                        color: Color(0xFF2E7D32), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fullName,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        Text(_cid,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                        if (_hosp.isNotEmpty)
                          Text('รพ. $_hosp',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.textHint),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final entry in widget.data.entries)
                    _buildSection(entry.key, entry.value as Map),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, Map data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor)),
          ),
          for (final kv in data.entries)
            if (kv.value.toString().isNotEmpty) ...[
              const Divider(height: 1, indent: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(kv.key,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary)),
                    ),
                    Expanded(
                      child: Text(kv.value.toString(),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
