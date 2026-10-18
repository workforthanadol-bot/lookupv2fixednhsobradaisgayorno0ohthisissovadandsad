import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../database/nhso_db_helper.dart';

class NhsoSearchScreen extends StatefulWidget {
  const NhsoSearchScreen({super.key});

  @override
  State<NhsoSearchScreen> createState() => _NhsoSearchScreenState();
}

class _NhsoSearchScreenState extends State<NhsoSearchScreen> {
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  bool _loading = false;
  bool? _dbAvailable;
  List<Map<String, dynamic>> _results = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkDb();
  }

  Future<void> _checkDb() async {
    final ok = await NhsoDbHelper.isAvailable();
    if (mounted) setState(() => _dbAvailable = ok);
  }

  Future<void> _search() async {
    final name = _nameCtrl.text.trim();
    final cid = _idCtrl.text.trim();
    if (name.isEmpty && cid.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final raw = await NhsoDbHelper.search(
        name: name.isNotEmpty ? name : null,
        citizenId: cid.isNotEmpty ? cid : null,
      );
      if (mounted) {
        setState(() {
          _results = raw;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'ค้นหาไม่สำเร็จ: $e';
          _loading = false;
        });
      }
    }
  }

  void _clear() {
    _nameCtrl.clear();
    _idCtrl.clear();
    setState(() {
      _results = [];
      _error = null;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหาข้อมูล สปสช'),
        actions: [
          if (_results.isNotEmpty || _nameCtrl.text.isNotEmpty || _idCtrl.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear_all), onPressed: _clear),
        ],
      ),
      body: Column(
        children: [
          // DB status banner
          if (_dbAvailable == false) _buildNoDB(),
          if (_dbAvailable == true) _buildSearchBar(),
          if (_dbAvailable == null)
            const LinearProgressIndicator(),

          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _results.isEmpty
                        ? _buildEmpty()
                        : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDB() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: AppTheme.warningColor, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ยังไม่มีฐานข้อมูล สปสช',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warningColor,
                        fontSize: 14)),
                SizedBox(height: 4),
                Text(
                  'วางไฟล์ฐานข้อมูลไว้ในโทรศัพท์:\n\n📁 /sdcard/Download/nhso_data.db\n\nหรือ\n\n📁 /storage/emulated/0/Download/nhso_data.db\n\nจากนั้นเปิดแอปใหม่ — ไม่ต้อง build APK ใหม่',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'ค้นหาด้วยชื่อ หรือ นามสกุล',
              prefixIcon: Icon(Icons.person_search_outlined),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _idCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 13,
            decoration: const InputDecoration(
              hintText: 'ค้นหาด้วยเลขบัตรประชาชน 13 หลัก',
              prefixIcon: Icon(Icons.credit_card_outlined),
              counterText: '',
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('ค้นหา'),
              onPressed: _search,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    if (_dbAvailable != true) return const SizedBox();
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search, size: 56, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('ค้นหาด้วยชื่อหรือเลขบัตรประชาชน',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_error!,
            style: const TextStyle(color: AppTheme.errorColor),
            textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _results.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('พบ ${_results.length} รายการ',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          );
        }
        final data = _results[i - 1];
        final output = NhsoDbHelper.buildOutput(data);
        return _NhsoCard(data: output);
      },
    );
  }
}

class _NhsoCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _NhsoCard({required this.data});

  @override
  State<_NhsoCard> createState() => _NhsoCardState();
}

class _NhsoCardState extends State<_NhsoCard> {
  bool _expanded = false;

  String get _fullName {
    final s1 = widget.data['ส่วนที่ ๑: ข้อมูลพื้นฐานบุคคล'] as Map?;
    return s1?['ชื่อ-นามสกุล']?.toString() ?? '-';
  }

  String get _cid {
    final s1 = widget.data['ส่วนที่ ๑: ข้อมูลพื้นฐานบุคคล'] as Map?;
    return s1?['เลขประจำตัวประชาชน']?.toString() ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person,
                        color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fullName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        Text(_cid,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textHint,
                  ),
                ],
              ),
            ),
          ),
          // Detail sections
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor)),
          ),
          for (final kv in data.entries)
            if (kv.value.toString().isNotEmpty) ...[
              const Divider(height: 1, indent: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(kv.key,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ),
                    Expanded(
                      child: Text(kv.value.toString(),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
