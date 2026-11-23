import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// Bottom sheet standar Nyawtat: latar `surface`, sudut atas membulat 24.
/// Pakai ini daripada `showModalBottomSheet` langsung supaya semua sheet
/// tampil sama.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  BoxConstraints? constraints,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    constraints: constraints,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: builder,
  );
}

/// Garis pegangan kecil di atas bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.handle,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

/// Isi form di bottom sheet: bisa digulir kalau layar pendek, font besar,
/// atau keyboard sedang terbuka.
class SheetScroll extends StatelessWidget {
  const SheetScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.xl,
          AppSpace.xl,
          AppSpace.xl,
          MediaQuery.viewInsetsOf(context).bottom + AppSpace.xxl,
        ),
        child: child,
      ),
    );
  }
}
