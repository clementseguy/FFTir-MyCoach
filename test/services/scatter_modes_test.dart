import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/utils/scatter_mode.dart';
import 'package:tir_sportif/utils/scatter_utils.dart';

void main() {
  group('Scatter modes (Lot E)', () {
    test('last10 returns last 10 chronological series', () {
      final now = DateTime(2025, 10, 3, 12);
      final sessions = <ShootingSession>[];
      // Build 15 series across 3 sessions
      for (int d = 3; d >= 1; d--) {
        final date = now.subtract(Duration(days: d));
        sessions.add(ShootingSession(
          id: d,
          date: date,
          weapon: 'P', caliber: '22LR',
          status: SessionConstants.statusRealisee,
          series: List.generate(5, (i) => Series(distance: 10, points: d*10 + i, groupSize: (d*10 + i).toDouble())),
        ));
      }
      // Flatten all series as in HomeScreen
      final all = <Map<String, dynamic>>[];
      for (final s in sessions..sort((a,b)=> (a.date??DateTime(1970)).compareTo(b.date??DateTime(1970)))) {
        final date = s.date!;
        for (final se in s.series) {
          all.add({'date': date, 'points': se.points.toDouble(), 'group_size': se.groupSize.toDouble()});
        }
      }
  final picked = selectScatterSeries(all, now: now, mode: ScatterMode.last10);
      expect(picked.length, 10);
      // Newest should be last
      expect(picked.first['date'].isBefore(picked.last['date']), isTrue);
    });

    test('window30Cap returns <=cap within 30 days, keeping most recent', () {
      final now = DateTime(2025, 10, 3, 12);
      final sessions = <ShootingSession>[];
      // 50 series within 30 days
      for (int d = 50; d >= 1; d--) {
        final date = now.subtract(Duration(days: d <= 25 ? d : (d - 25))); // ensure many within 30 days
        sessions.add(ShootingSession(
          id: d,
          date: date,
          weapon: 'P', caliber: '22LR',
          status: SessionConstants.statusRealisee,
          series: [Series(distance: 10, points: d, groupSize: d.toDouble())],
        ));
      }
      final all = <Map<String, dynamic>>[];
      for (final s in sessions..sort((a,b)=> (a.date??DateTime(1970)).compareTo(b.date??DateTime(1970)))) {
        final date = s.date!;
        for (final se in s.series) {
          all.add({'date': date, 'points': se.points.toDouble(), 'group_size': se.groupSize.toDouble()});
        }
      }
  final picked = selectScatterSeries(all, now: now, mode: ScatterMode.window30Cap);
      expect(picked.length <= ScatterConfig.capN, isTrue);
      // Ensure the last item is the most recent
      expect(picked.last['date'].isAtSameMomentAs(all.last['date']), isTrue);
    });

    test('downsample stride keeps last point and reduces length near target', () {
      final list = List.generate(200, (i) => {'date': DateTime(2025, 10, 1).add(Duration(minutes: i)), 'points': i.toDouble(), 'group_size': i.toDouble()});
  final ds = downsampleStride(list, target: 60);
      expect(ds.length <= 61, isTrue); // allow +1 for forced last
      expect(ds.last['date'].isAtSameMomentAs(list.last['date']), isTrue);
    });
  });
}
