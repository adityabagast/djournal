import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Ikon kategori yang bisa dipilih. Kuncinya disimpan di kolom
/// `categories.icon` (ikut sync dan backup), jadi jangan diganti namanya;
/// menambah kunci baru aman.
const categoryIcons = <String, IconData>{
  'makan': Icons.restaurant,
  'kopi': Icons.local_cafe_outlined,
  'mobil': Icons.directions_car_outlined,
  'motor': Icons.two_wheeler,
  'belanja': Icons.shopping_cart_outlined,
  'tagihan': Icons.receipt_long_outlined,
  'kuota': Icons.wifi,
  'film': Icons.movie_outlined,
  'sehat': Icons.favorite_border,
  'sekolah': Icons.school_outlined,
  'hadiah': Icons.card_giftcard,
  'baju': Icons.checkroom,
  'rumah': Icons.home_outlined,
  'sosial': Icons.group_outlined,
  'sedekah': Icons.volunteer_activism_outlined,
  'gaji': Icons.work_outline,
  'tabungan': Icons.savings_outlined,
  'investasi': Icons.trending_up,
  'jalan': Icons.flight,
};

/// Nama ikon untuk pembaca layar dan tooltip.
String categoryIconLabel(AppLocalizations l, String key) => switch (key) {
  'makan' => l.iconFood,
  'kopi' => l.iconCoffee,
  'mobil' => l.iconCar,
  'motor' => l.iconMotorbike,
  'belanja' => l.iconShopping,
  'tagihan' => l.iconBills,
  'kuota' => l.iconData,
  'film' => l.iconEntertainment,
  'sehat' => l.iconHealth,
  'sekolah' => l.iconEducation,
  'hadiah' => l.iconGift,
  'baju' => l.iconClothes,
  'rumah' => l.iconHome,
  'sosial' => l.iconFriends,
  'sedekah' => l.iconCharity,
  'gaji' => l.iconSalary,
  'tabungan' => l.iconSavings,
  'investasi' => l.iconInvestment,
  'jalan' => l.iconTravel,
  _ => key,
};
