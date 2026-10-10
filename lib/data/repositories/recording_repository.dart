import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/recording_meta.dart';
import '../models/sample.dart';

/// Stores labelled accelerometer recordings as CSV files.
///
/// Format:
///   # quakewatch v1
///   # label=...
///   # rate_hz=...
///   # created=ISO-8601
///   # note=...
///   t_ms,x,y,z
///   0,0.12,0.03,9.81
class RecordingRepository {
  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/recordings');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<RecordingMeta> save({
    required String label,
    required String note,
    required List<Sample> samples,
    required DateTime created,
  }) async {
    final dir = await _dir();
    final slug = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final stamp = created.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final name = '${slug}_$stamp.csv';
    final file = File('${dir.path}/$name');

    final durationMs = samples.isEmpty ? 0 : samples.last.tMs;
    final rate = durationMs > 0 ? samples.length * 1000 / durationMs : 0.0;

    final b = StringBuffer()
      ..writeln('# quakewatch v1')
      ..writeln('# label=$label')
      ..writeln('# rate_hz=${rate.toStringAsFixed(2)}')
      ..writeln('# created=${created.toIso8601String()}')
      ..writeln('# note=${note.replaceAll('\n', ' ')}')
      ..writeln('t_ms,x,y,z');
    for (final s in samples) {
      b.writeln(
          '${s.tMs},${s.x.toStringAsFixed(4)},${s.y.toStringAsFixed(4)},${s.z.toStringAsFixed(4)}');
    }
    await file.writeAsString(b.toString(), flush: true);

    return RecordingMeta(
      path: file.path,
      name: name,
      label: label,
      rateHz: rate,
      created: created,
      sampleCount: samples.length,
      durationMs: durationMs,
      note: note,
    );
  }

  Future<List<RecordingMeta>> list() async {
    final dir = await _dir();
    final metas = <RecordingMeta>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.csv')) {
        try {
          metas.add(await _readMeta(entity));
        } catch (_) {
          // skip unreadable files
        }
      }
    }
    metas.sort((a, b) => b.created.compareTo(a.created));
    return metas;
  }

  Future<List<Sample>> load(String path) async {
    final lines = await File(path).readAsLines();
    final out = <Sample>[];
    for (final line in lines) {
      final s = _parseRow(line);
      if (s != null) out.add(s);
    }
    return out;
  }

  Future<void> delete(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  Future<RecordingMeta> _readMeta(File file) async {
    final lines = await file.readAsLines();
    final header = <String, String>{};
    var count = 0;
    var lastT = 0;
    for (final line in lines) {
      if (line.startsWith('#')) {
        final body = line.substring(1).trim();
        final i = body.indexOf('=');
        if (i > 0) header[body.substring(0, i)] = body.substring(i + 1);
      } else {
        final s = _parseRow(line);
        if (s != null) {
          count++;
          lastT = s.tMs;
        }
      }
    }
    return RecordingMeta(
      path: file.path,
      name: file.uri.pathSegments.last,
      label: header['label'] ?? 'Unlabelled',
      rateHz: double.tryParse(header['rate_hz'] ?? '') ?? 50,
      created: DateTime.tryParse(header['created'] ?? '') ??
          file.lastModifiedSync(),
      sampleCount: count,
      durationMs: lastT,
      note: header['note'] ?? '',
    );
  }

  Sample? _parseRow(String line) {
    if (line.isEmpty || line.startsWith('#') || line.startsWith('t_ms')) {
      return null;
    }
    final p = line.split(',');
    if (p.length < 4) return null;
    final t = int.tryParse(p[0]);
    final x = double.tryParse(p[1]);
    final y = double.tryParse(p[2]);
    final z = double.tryParse(p[3]);
    if (t == null || x == null || y == null || z == null) return null;
    return Sample(t, x, y, z);
  }
}
