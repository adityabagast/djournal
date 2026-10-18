import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';

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
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.paths.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.handle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ambil Gambar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library_rounded, color: c.primary),
                ),
                title: Text(
                  'Galeri Foto',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink),
                ),
                subtitle: Text(
                  'Pilih foto dari penyimpanan perangkat',
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: c.primary),
                ),
                title: Text(
                  'Kamera',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink),
                ),
                subtitle: Text(
                  'Ambil foto baru secara langsung',
                  style: TextStyle(fontSize: 12, color: c.muted),
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

/// Widget Grid Lampiran Gambar untuk Form Jurnal.
class JournalImageGrid extends StatelessWidget {
  const JournalImageGrid({
    super.key,
    required this.imagePaths,
    required this.onAddImage,
    required this.onRemoveImage,
    this.maxImages = 10,
  });

  final List<String> imagePaths;
  final VoidCallback onAddImage;
  final ValueChanged<int> onRemoveImage;
  final int maxImages;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canAddMore = imagePaths.length < maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tombol cepat Galeri & Kamera
        Row(
          children: [
            Expanded(
              child: _ActionImageButton(
                icon: Icons.photo_library_rounded,
                label: 'Galeri',
                onTap: () => onAddImage(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionImageButton(
                icon: Icons.camera_alt_rounded,
                label: 'Kamera',
                onTap: () => onAddImage(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid Thumbnail
        if (imagePaths.isNotEmpty || canAddMore)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: imagePaths.length + (canAddMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < imagePaths.length) {
                final path = imagePaths[index];
                final file = File(path);
                return Stack(
                  children: [
                    // Gambar Thumbnail
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => openImageViewer(
                          context,
                          paths: imagePaths,
                          initialIndex: index,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: file.existsSync()
                              ? Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  cacheWidth: 300,
                                  errorBuilder: (_, err, stack) => Container(
                                    color: c.subtle,
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: c.muted,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: c.subtle,
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    color: c.muted,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Badge Nomor Urut
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: c.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Tombol Hapus
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemoveImage(index),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Sel Tambah Foto
              return GestureDetector(
                onTap: onAddImage,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: c.line,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                    color: c.surface,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 24, color: c.muted),
                      const SizedBox(height: 2),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 4),
        Text(
          'Maks $maxImages gambar · JPEG dikompres ke 1600px',
          style: TextStyle(fontSize: 11, color: c.muted),
        ),
      ],
    );
  }
}

class _ActionImageButton extends StatelessWidget {
  const _ActionImageButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primarySoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: c.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPickReceipt,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: c.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 36, color: c.primary),
                const SizedBox(height: 8),
                Text(
                  'Foto Struk Belanja',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ambil dari kamera atau galeri',
                  style: TextStyle(
                    fontSize: 12,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Struk dengan Tap to View
          GestureDetector(
            onTap: () => openImageViewer(context, paths: [path]),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: c.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Struk terlampir (ketuk untuk perbesar)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onPickReceipt,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Ganti', style: TextStyle(fontSize: 12)),
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
