import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';

/// Pose maskot kucing-halaman; nama = file di assets/mascot/.
enum MascotPose {
  halo,
  menulis,
  koin,
  tidur,
  senang,
  gembok,
  sedih,
  mencari,
  sinkron,
}

/// Latar pastel di belakang maskot, sama dengan desain di kanvas.
abstract final class MascotTint {
  static const mint = Color(0xFFE3F3EA);
  static const peach = Color(0xFFFDEBD9);
  static const lemon = Color(0xFFFBF3D6);
  static const sky = Color(0xFFE3EDF8);
  static const pink = Color(0xFFFBE4E6);
  static const lilac = Color(0xFFECE6F6);
  static const rose = Color(0xFFF3E3E0);
}

/// Gambar maskot. Hiasan saja: tidak dibacakan pembaca layar.
class Mascot extends StatelessWidget {
  const Mascot(this.pose, {super.key, this.size = 120});

  final MascotPose pose;

  /// Lebar gambar; tingginya 1,1 × lebar (viewBox 200×220).
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/mascot/${pose.name}.svg',
      width: size,
      height: size * 1.1,
      excludeFromSemantics: true,
    );
  }
}

/// Maskot di dalam lingkaran pastel.
class MascotBadge extends StatelessWidget {
  const MascotBadge(
    this.pose, {
    super.key,
    required this.tint,
    this.size = 150,
  });

  final MascotPose pose;
  final Color tint;

  /// Diameter lingkaran.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
      child: Mascot(pose, size: size * 0.75),
    );
  }
}

/// Keadaan kosong: maskot, judul, penjelasan, dan tombol opsional.
class MascotEmpty extends StatelessWidget {
  const MascotEmpty({
    super.key,
    required this.pose,
    required this.tint,
    required this.title,
    required this.message,
    this.action,
    this.size = 150,
  });

  final MascotPose pose;
  final Color tint;
  final String title;
  final String message;
  final Widget? action;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // Lebar penuh supaya tetap di tengah walau induknya rata kiri.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          MascotBadge(pose, tint: tint, size: size),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

/// Snackbar dengan maskot kecil. Secara bawaan melayang di atas dock
/// navigasi; [aboveDock] false untuk halaman tanpa dock (mis. Pengaturan).
void showMascotSnackBar(
  BuildContext context,
  MascotPose pose,
  String text, {
  bool aboveDock = true,
}) {
  final bottom = aboveDock ? 104 + MediaQuery.paddingOf(context).bottom : 16.0;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
        backgroundColor: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.line),
        ),
        content: Row(
          children: [
            Mascot(pose, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
