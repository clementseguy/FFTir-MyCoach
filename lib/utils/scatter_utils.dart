import 'scatter_mode.dart';

/// Select a subset of series for the scatter chart based on the given [mode].
/// [allSeriesAsc] must be chronological ascending (oldest -> newest) and each map must include keys: 'date', 'points', 'group_size'.
List<Map<String, dynamic>> selectScatterSeries(
  List<Map<String, dynamic>> allSeriesAsc, {
  required DateTime now,
  ScatterMode mode = ScatterMode.last10,
}) {
  if (allSeriesAsc.isEmpty) return [];
  switch (mode) {
    case ScatterMode.last10:
      final n = allSeriesAsc.length;
      final start = n > 10 ? (n - 10) : 0;
      return allSeriesAsc.sublist(start, n);
    case ScatterMode.window30Cap:
      final cutoff = now.subtract(Duration(days: ScatterConfig.windowDays));
      final within = allSeriesAsc.where((e) => (e['date'] as DateTime).isAfter(cutoff)).toList();
      if (within.length <= ScatterConfig.capN) return within;
      return within.sublist(within.length - ScatterConfig.capN);
    case ScatterMode.adaptive:
      final cutoff = now.subtract(Duration(days: ScatterConfig.windowDays));
      final within = allSeriesAsc.where((e) => (e['date'] as DateTime).isAfter(cutoff)).toList();
      if (within.length <= 20) return within;
      if (within.length <= 60) {
        // cap to 40 for medium density
        const cap = 40;
        return within.sublist(within.length - cap);
      }
      // downsample to target ~60 points using simple stride
      return downsampleStride(within, target: ScatterConfig.downsampleTarget);
  }
}

/// Simple stride-based downsampling to reduce the number of points while preserving the last point.
List<Map<String, dynamic>> downsampleStride(List<Map<String, dynamic>> list, {int target = 60}) {
  if (list.length <= target) return list;
  final stride = (list.length / target).ceil();
  final out = <Map<String, dynamic>>[];
  for (int i = 0; i < list.length; i += stride) {
    out.add(list[i]);
  }
  if (out.isEmpty || out.last != list.last) out.add(list.last);
  return out;
}
