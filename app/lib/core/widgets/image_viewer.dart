import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';
import '../tokens.dart';
import 'app_sheet.dart';

/// Membuka dialog fullscreen untuk melihat gambar dengan kemampuan zoom & swipe.
void openImageViewer(
  BuildContext context, {
  required List<String> paths,
  int initialIndex = 0,
}) {
  if (paths.isEmpty) return;
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      barrierDismissible: true,
      pageBuilder: (context, anim, secAnim) {
        return _ImageViewerScreen(paths: paths, initialIndex: initialIndex);
      },
    ),
  );
}

class _ImageViewerScreen extends StatefulWidget {
  const _ImageViewerScreen({required this.paths, required this.initialIndex});

  final List<String> paths;
  final int initialIndex;

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Gambar interaktif dengan pinch-to-zoom
            PageView.builder(
              controller: _pageController,
              itemCount: widget.paths.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, i) {
                final file = File(widget.paths[i]);
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: file.existsSync()
                        ? Image.file(
                            file,
                            fit: BoxFit.contain,
                            errorBuilder: (_, err, stack) => const Icon(
                              Icons.broken_image_rounded,
                              color: Colors.white70,
                              size: 64,
                            ),
                          )
                        : const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white70,
                            size: 64,
                          ),
                  ),
                );
              },
            ),

            // Top Bar: Tombol Tutup & Indikator Halaman
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (widget.paths.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.paths.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSize.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal bottom sheet untuk memilih sumber gambar: Galeri atau Kamera.
Future<ImageSource?> showImageSourcePicker(BuildContext context) {
  final c = context.colors;
  return showAppSheet<ImageSource>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: AppSpace.lg),
              Text(
                'Ambil Gambar',
                style: TextStyle(
                  fontSize: AppFontSize.title,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.photo_library_rounded, color: c.primary),
                ),
                title: Text(
                  'Galeri Foto',
                  style: TextStyle(fontSize: AppFontSize.title, fontWeight: FontWeight.w600, color: c.ink),
                ),
                subtitle: Text(
                  'Pilih foto dari penyimpanan perangkat',
                  style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: AppSpace.sm),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: c.primary),
                ),
                title: Text(
                  'Kamera',
                  style: TextStyle(fontSize: AppFontSize.title, fontWeight: FontWeight.w600, color: c.ink),
                ),
                subtitle: Text(
                  'Ambil foto baru secara langsung',
                  style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Widget Foto Struk / Receipt untuk Form Transaksi Keuangan.
class TxReceiptSection extends StatelessWidget {
  const TxReceiptSection({
    super.key,
    required this.receiptPath,
    required this.onPickReceipt,
    required this.onRemoveReceipt,
  });

  final String? receiptPath;
  final VoidCallback onPickReceipt;
  final VoidCallback onRemoveReceipt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final path = receiptPath;

    if (path == null) {
      return Material(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onPickReceipt,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl, horizontal: AppSpace.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: c.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 36, color: c.primary),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Foto Struk Belanja',
                  style: TextStyle(
                    fontSize: AppFontSize.bodyLg,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  'Ambil dari kamera atau galeri',
                  style: TextStyle(
                    fontSize: AppFontSize.meta,
                    color: c.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final file = File(path);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Struk dengan Tap to View
          GestureDetector(
            onTap: () => openImageViewer(context, paths: [path]),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: file.existsSync()
                    ? Image.file(
                        file,
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                        errorBuilder: (_, err, stack) => Container(
                          color: c.subtle,
                          child: Icon(Icons.broken_image_rounded, color: c.muted, size: 36),
                        ),
                      )
                    : Container(
                        color: c.subtle,
                        child: Icon(Icons.broken_image_rounded, color: c.muted, size: 36),
                      ),
              ),
            ),
          ),

          // Action row di bawah struk: Ganti & Hapus
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: c.primary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    'Struk terlampir (ketuk untuk perbesar)',
                    style: TextStyle(
                      fontSize: AppFontSize.meta,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onPickReceipt,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Ganti', style: TextStyle(fontSize: AppFontSize.meta)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: c.primary,
                  ),
                ),
                IconButton(
                  onPressed: onRemoveReceipt,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: c.expense,
                  tooltip: 'Hapus Struk',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
