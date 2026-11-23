import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/changelog.dart';

/// Riwayat versi dari salinan CHANGELOG.md di aset (tanpa internet).
final changelogProvider = FutureProvider<List<ChangelogEntry>>(
  (ref) async =>
      parseChangelog(await rootBundle.loadString('assets/changelog.md')),
);
