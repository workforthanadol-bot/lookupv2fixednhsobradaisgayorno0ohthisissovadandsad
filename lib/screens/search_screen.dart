import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/candidate.dart';
import '../providers/search_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/candidate_card.dart';
import 'detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchFiltersProvider.notifier).setQuery(value);
    });
  }

  void _clearAll() {
    _searchCtrl.clear();
    ref.read(searchFiltersProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final results = ref.watch(searchResultsProvider);
    final regions = ref.watch(regionsProvider);
    final provinces = ref.watch(provincesProvider);
    final statuses = ref.watch(statusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหาข้อมูลผู้สมัครสอบ'),
        actions: [
          if (filters.hasAnyFilter)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'ล้างตัวกรอง',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // ---- Search input ----
          Container(
            color: AppTheme.primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onQueryChanged,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'ค้นหา เลขประจำตัวสอบ / ชื่อ-นามสกุล / เลขบัตรประชาชน',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textHint,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(searchFiltersProvider.notifier).setQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // ---- Filter dropdowns ----
          Container(
            color: AppTheme.scaffoldBg,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _FilterDropdown(
                    label: 'ภาค/เขต',
                    value: filters.region.isEmpty ? null : filters.region,
                    items: regions.valueOrNull ?? [],
                    onChanged: (v) =>
                        ref.read(searchFiltersProvider.notifier).setRegion(v ?? ''),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterDropdown(
                    label: 'จังหวัด',
                    value: filters.province.isEmpty ? null : filters.province,
                    items: provinces.valueOrNull ?? [],
                    onChanged: (v) =>
                        ref.read(searchFiltersProvider.notifier).setProvince(v ?? ''),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _FilterDropdown(
              label: 'สถานะ',
              value: filters.status.isEmpty ? null : filters.status,
              items: statuses.valueOrNull ?? [],
              onChanged: (v) =>
                  ref.read(searchFiltersProvider.notifier).setStatus(v ?? ''),
            ),
          ),

          // ---- Results ----
          Expanded(
            child: results.when(
              data: (data) => _buildResults(data, filters),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppTheme.errorColor),
                      const SizedBox(height: 12),
                      Text(
                        'เกิดข้อผิดพลาด: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<Candidate> data, SearchFilters filters) {
    if (!filters.hasAnyFilter) {
      return _buildEmptyState(
        icon: Icons.manage_search,
        message: 'พิมพ์ชื่อหรือเลขประจำตัวสอบเพื่อค้นหา',
        sub: 'รองรับการค้นหาด้วยชื่อ-นามสกุล, เลขประจำตัวสอบ\nหรือเลขบัตรประชาชน',
      );
    }
    if (data.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        message: 'ไม่พบข้อมูลที่ตรงกัน',
        sub: 'ลองเปลี่ยนคำค้นหาหรือปรับตัวกรองใหม่',
      );
    }

    return Column(
      children: [
        // Result count bar
        Container(
          width: double.infinity,
          color: AppTheme.primaryColor.withOpacity(0.05),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'พบ ${data.length} รายการ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final c = data[i];
              return CandidateCard(
                candidate: c,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(candidate: c),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String sub,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.primaryColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textHint,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value != null
              ? AppTheme.primaryColor
              : const Color(0xFFCDD5E0),
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textHint,
            ),
          ),
          icon: Icon(
            Icons.expand_more,
            size: 20,
            color: value != null ? AppTheme.primaryColor : AppTheme.textHint,
          ),
          isExpanded: true,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textPrimary,
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('ทั้งหมด ($label)'),
            ),
            ...items.map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
