import 'dart:math';

/// Batu gunting kertas. Urutan penting: tiap tangan mengalahkan tangan
/// berikutnya (batu > gunting > kertas > batu).
enum Hand { rock, scissors, paper }

enum RpsOutcome { win, lose, tie }

RpsOutcome playRps(Hand me, Hand other) {
  if (me == other) return RpsOutcome.tie;
  return Hand.values[(me.index + 1) % Hand.values.length] == other
      ? RpsOutcome.win
      : RpsOutcome.lose;
}

/// Roda putar. Rotasi dalam putaran (1.0 = 360°) searah jarum jam, jarum di
/// atas, irisan 0 dimulai dari atas.
abstract final class Wheel {
  static const minOptions = 2;
  static const maxOptions = 12;
  static const maxLabelLength = 20;

  /// Irisan yang berada di bawah jarum untuk rotasi [turns].
  static int indexAt(double turns, int count) {
    final top = (1 - turns % 1) % 1;
    return (top * count).floor() % count;
  }

  /// Rotasi baru yang selalu maju minimal [spins] putaran dan berhenti di
  /// tengah-tengah irisan [index] (tidak tepat di garis batas).
  static double target(
    double current,
    int index,
    int count,
    Random random, {
    int spins = 6,
  }) {
    final top = (index + 0.2 + random.nextDouble() * 0.6) / count;
    return current.floorToDouble() + spins + (1 - top);
  }

  /// Jumlah warna per palet roda.
  static const colorSlots = 6;

  /// Slot warna irisan [i]; irisan terakhir tidak sama dengan irisan pertama.
  static int colorSlot(int i, int count, {int slots = colorSlots}) {
    final k = i % slots;
    return i == count - 1 && count > 1 && k == 0 ? 2 % slots : k;
  }
}

/// Pilihan warna roda (palet + warna kustom).
class WheelColors {
  const WheelColors({this.palette = defaultPalette, this.custom = defaults});

  static const defaultPalette = 'rainbow';
  static const palettes = [
    'rainbow',
    'accent',
    'pastel',
    'sunset',
    'ocean',
    'forest',
    'custom',
  ];

  static const defaults = [
    '#9AD8C0',
    '#F6B8B8',
    '#A9C8F0',
    '#F7D58B',
    '#CDB4EE',
    '#B9E3A3',
  ];

  final String palette;
  final List<String> custom;

  bool get isCustom => palette == 'custom';

  static final _hex = RegExp(r'^#[0-9A-F]{6}$');

  /// Data tidak valid → nilai bawaan.
  factory WheelColors.fromJson(Map<String, dynamic> j) {
    final p = j['palette'];
    final c = j['custom'];
    final list = c is List
        ? [for (final x in c) x is String ? x.toUpperCase() : '']
        : const <String>[];
    return WheelColors(
      palette: palettes.contains(p) ? p as String : defaultPalette,
      custom: list.length == Wheel.colorSlots && list.every(_hex.hasMatch)
          ? List.unmodifiable(list)
          : defaults,
    );
  }

  Map<String, dynamic> toJson() => {'palette': palette, 'custom': custom};

  WheelColors withPalette(String p) => WheelColors(palette: p, custom: custom);

  WheelColors withSlot(int slot, String hex) => WheelColors(
    palette: palette,
    custom: [
      for (var i = 0; i < custom.length; i++)
        i == slot ? hex.toUpperCase() : custom[i],
    ],
  );

  WheelColors resetCustom() => WheelColors(palette: palette);
}

/// Memory kartu: 6 pasang, kartu terbuka dua-dua. Pasangan yang cocok tetap
/// terbuka; yang tidak cocok ditutup lagi lewat [hideMismatch].
class MemoryGame {
  MemoryGame(Random random) : deck = _shuffled(random);

  static const pairs = 6;

  /// Nomor pasangan (0..5) di tiap posisi kartu.
  final List<int> deck;
  final Set<int> matched = {};
  final List<int> open = [];
  int moves = 0;

  bool get won => matched.length == deck.length;

  /// Dua kartu terbuka dan tidak cocok: menunggu ditutup.
  bool get mismatch => open.length == 2;

  /// Membalik kartu [i]; false kalau diabaikan.
  bool flip(int i) {
    if (won || mismatch || matched.contains(i) || open.contains(i)) {
      return false;
    }
    open.add(i);
    if (open.length == 2) {
      moves++;
      if (deck[open[0]] == deck[open[1]]) {
        matched.addAll(open);
        open.clear();
      }
    }
    return true;
  }

  void hideMismatch() => open.clear();

  static List<int> _shuffled(Random random) => [
    for (var k = 0; k < pairs; k++) ...[k, k],
  ]..shuffle(random);
}

/// Kantong kocok: mengeluarkan semua nomor 0..n-1 dalam urutan acak sebelum
/// ada yang muncul lagi, dan tidak pernah memberi nomor yang sama dua kali
/// berturut-turut (juga di antara dua putaran kantong).
class ShuffleBag {
  ShuffleBag(this.count, this._random) : assert(count > 0);

  final int count;
  final Random _random;
  final List<int> _order = [];
  int _pos = 0;
  int? _last;

  int next() {
    if (_pos >= _order.length) {
      _order
        ..clear()
        ..addAll(List.generate(count, (i) => i))
        ..shuffle(_random);
      if (count > 1 && _order.first == _last) {
        final j = 1 + _random.nextInt(count - 1);
        final t = _order[0];
        _order[0] = _order[j];
        _order[j] = t;
      }
      _pos = 0;
    }
    return _last = _order[_pos++];
  }
}
