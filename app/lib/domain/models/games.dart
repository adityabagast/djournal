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
