import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/candidate.dart';

// ---- Filter state ----
class SearchFilters {
  final String query;
  final String region;
  final String province;
  final String status;

  const SearchFilters({
    this.query = '',
    this.region = '',
    this.province = '',
    this.status = '',
  });

  SearchFilters copyWith({
    String? query,
    String? region,
    String? province,
    String? status,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      region: region ?? this.region,
      province: province ?? this.province,
      status: status ?? this.status,
    );
  }

  bool get hasAnyFilter =>
      query.isNotEmpty || region.isNotEmpty || province.isNotEmpty || status.isNotEmpty;
}

class SearchFiltersNotifier extends StateNotifier<SearchFilters> {
  SearchFiltersNotifier() : super(const SearchFilters());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setRegion(String r) => state = state.copyWith(region: r);
  void setProvince(String p) => state = state.copyWith(province: p);
  void setStatus(String s) => state = state.copyWith(status: s);
  void clear() => state = const SearchFilters();
}

final searchFiltersProvider =
    StateNotifierProvider<SearchFiltersNotifier, SearchFilters>(
  (ref) => SearchFiltersNotifier(),
);

// ---- Search results ----
final searchResultsProvider = FutureProvider.autoDispose<List<Candidate>>((ref) async {
  final filters = ref.watch(searchFiltersProvider);
  if (!filters.hasAnyFilter) return [];
  return DbHelper.instance.search(
    query: filters.query,
    region: filters.region,
    province: filters.province,
    status: filters.status,
  );
});

// ---- Dropdown data ----
final regionsProvider = FutureProvider<List<String>>((ref) async {
  return DbHelper.instance.getDistinctValues('region');
});

final provincesProvider = FutureProvider<List<String>>((ref) async {
  return DbHelper.instance.getDistinctValues('province');
});

final statusesProvider = FutureProvider<List<String>>((ref) async {
  return DbHelper.instance.getDistinctValues('status');
});

// ---- PDF export selected candidates ----
final selectedCandidatesProvider =
    StateNotifierProvider<SelectedCandidatesNotifier, List<Candidate>>(
  (ref) => SelectedCandidatesNotifier(),
);

class SelectedCandidatesNotifier extends StateNotifier<List<Candidate>> {
  SelectedCandidatesNotifier() : super([]);

  void toggle(Candidate c) {
    if (state.any((s) => s.id == c.id)) {
      state = state.where((s) => s.id != c.id).toList();
    } else {
      state = [...state, c];
    }
  }

  void setAll(List<Candidate> candidates) => state = List.from(candidates);
  void clear() => state = [];
  bool isSelected(Candidate c) => state.any((s) => s.id == c.id);
}
