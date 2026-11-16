import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'Nyawtat'**
  String get appName;

  /// No description provided for @splashTagline.
  ///
  /// In id, this message translates to:
  /// **'jurnal & catatan uang'**
  String get splashTagline;

  /// No description provided for @navToday.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get navToday;

  /// No description provided for @navJournal.
  ///
  /// In id, this message translates to:
  /// **'Jurnal'**
  String get navJournal;

  /// No description provided for @navMoney.
  ///
  /// In id, this message translates to:
  /// **'Keuangan'**
  String get navMoney;

  /// No description provided for @navReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get navReport;

  /// No description provided for @add.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get add;

  /// No description provided for @back.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get delete;

  /// No description provided for @today.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In id, this message translates to:
  /// **'Kemarin'**
  String get yesterday;

  /// No description provided for @comingSoon.
  ///
  /// In id, this message translates to:
  /// **'Segera hadir di fase berikutnya.'**
  String get comingSoon;

  /// No description provided for @todaySpent.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran hari ini'**
  String get todaySpent;

  /// No description provided for @monthSpent.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini {amount}'**
  String monthSpent(String amount);

  /// No description provided for @record.
  ///
  /// In id, this message translates to:
  /// **'Catat'**
  String get record;

  /// No description provided for @todayTimeline.
  ///
  /// In id, this message translates to:
  /// **'Timeline hari ini'**
  String get todayTimeline;

  /// No description provided for @write.
  ///
  /// In id, this message translates to:
  /// **'Tulis'**
  String get write;

  /// No description provided for @timelineEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada catatan hari ini. Tulis jurnal atau catat transaksi pertamamu.'**
  String get timelineEmpty;

  /// No description provided for @totalBalance.
  ///
  /// In id, this message translates to:
  /// **'Total saldo'**
  String get totalBalance;

  /// No description provided for @income.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get expense;

  /// No description provided for @net.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get net;

  /// No description provided for @wallets.
  ///
  /// In id, this message translates to:
  /// **'Dompet'**
  String get wallets;

  /// No description provided for @addWallet.
  ///
  /// In id, this message translates to:
  /// **'Tambah dompet'**
  String get addWallet;

  /// No description provided for @filterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get filterAll;

  /// No description provided for @noTransactions.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi.'**
  String get noTransactions;

  /// No description provided for @addTxTitle.
  ///
  /// In id, this message translates to:
  /// **'Catat Transaksi'**
  String get addTxTitle;

  /// No description provided for @editTxTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Transaksi'**
  String get editTxTitle;

  /// No description provided for @amount.
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get amount;

  /// No description provided for @amountRequired.
  ///
  /// In id, this message translates to:
  /// **'Isi nominal dulu ya.'**
  String get amountRequired;

  /// No description provided for @category.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @wallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet'**
  String get wallet;

  /// No description provided for @time.
  ///
  /// In id, this message translates to:
  /// **'Waktu'**
  String get time;

  /// No description provided for @note.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get note;

  /// No description provided for @noteHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: makan siang di kantin'**
  String get noteHint;

  /// No description provided for @saveTx.
  ///
  /// In id, this message translates to:
  /// **'Simpan transaksi'**
  String get saveTx;

  /// No description provided for @transferFrom.
  ///
  /// In id, this message translates to:
  /// **'Dari'**
  String get transferFrom;

  /// No description provided for @transferTo.
  ///
  /// In id, this message translates to:
  /// **'Ke'**
  String get transferTo;

  /// No description provided for @walletBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo {amount}'**
  String walletBalance(String amount);

  /// No description provided for @swapWallets.
  ///
  /// In id, this message translates to:
  /// **'Tukar dompet asal dan tujuan'**
  String get swapWallets;

  /// No description provided for @transferOverdraw.
  ///
  /// In id, this message translates to:
  /// **'Saldo {wallet} kurang dari nominal. Tetap bisa disimpan.'**
  String transferOverdraw(String wallet);

  /// No description provided for @transferNeedsTwoWallets.
  ///
  /// In id, this message translates to:
  /// **'Transfer butuh minimal 2 dompet.'**
  String get transferNeedsTwoWallets;

  /// No description provided for @saveTransfer.
  ///
  /// In id, this message translates to:
  /// **'Simpan transfer'**
  String get saveTransfer;

  /// No description provided for @transferNoteHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: tarik tunai di ATM'**
  String get transferNoteHint;

  /// No description provided for @toastTransferSaved.
  ///
  /// In id, this message translates to:
  /// **'Transfer tersimpan'**
  String get toastTransferSaved;

  /// No description provided for @deleteTxConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus transaksi ini?'**
  String get deleteTxConfirm;

  /// No description provided for @quickAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah cepat'**
  String get quickAdd;

  /// No description provided for @quickAddTx.
  ///
  /// In id, this message translates to:
  /// **'Catat transaksi'**
  String get quickAddTx;

  /// No description provided for @quickAddTxSub.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran, pemasukan, atau transfer'**
  String get quickAddTxSub;

  /// No description provided for @quickAddJournal.
  ///
  /// In id, this message translates to:
  /// **'Tulis jurnal'**
  String get quickAddJournal;

  /// No description provided for @quickAddJournalSub.
  ///
  /// In id, this message translates to:
  /// **'Cerita baru, jam dan mood opsional'**
  String get quickAddJournalSub;

  /// No description provided for @reportByCategory.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran per kategori'**
  String get reportByCategory;

  /// No description provided for @reportEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pengeluaran bulan ini.'**
  String get reportEmpty;

  /// No description provided for @settings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In id, this message translates to:
  /// **'Tampilan'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get themeDark;

  /// No description provided for @themeSystemHint.
  ///
  /// In id, this message translates to:
  /// **'Mengikuti mode gelap di pengaturan HP. Widget layar utama ikut juga.'**
  String get themeSystemHint;

  /// No description provided for @themeLightHint.
  ///
  /// In id, this message translates to:
  /// **'Selalu terang, apa pun pengaturan HP. Widget layar utama ikut juga.'**
  String get themeLightHint;

  /// No description provided for @themeDarkHint.
  ///
  /// In id, this message translates to:
  /// **'Selalu gelap, apa pun pengaturan HP. Widget layar utama ikut juga.'**
  String get themeDarkHint;

  /// No description provided for @accentTitle.
  ///
  /// In id, this message translates to:
  /// **'Warna aksen'**
  String get accentTitle;

  /// No description provided for @accentHint.
  ///
  /// In id, this message translates to:
  /// **'Dipakai untuk tombol, ikon aktif, dan kartu Total saldo. Berlaku di mode terang dan gelap.'**
  String get accentHint;

  /// No description provided for @accentSage.
  ///
  /// In id, this message translates to:
  /// **'Hijau sage'**
  String get accentSage;

  /// No description provided for @accentOcean.
  ///
  /// In id, this message translates to:
  /// **'Biru laut'**
  String get accentOcean;

  /// No description provided for @accentViolet.
  ///
  /// In id, this message translates to:
  /// **'Ungu'**
  String get accentViolet;

  /// No description provided for @accentRose.
  ///
  /// In id, this message translates to:
  /// **'Mawar'**
  String get accentRose;

  /// No description provided for @accentPink.
  ///
  /// In id, this message translates to:
  /// **'Pink'**
  String get accentPink;

  /// No description provided for @accentAmber.
  ///
  /// In id, this message translates to:
  /// **'Amber'**
  String get accentAmber;

  /// No description provided for @accentTeal.
  ///
  /// In id, this message translates to:
  /// **'Teal'**
  String get accentTeal;

  /// No description provided for @accentCustom.
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get accentCustom;

  /// No description provided for @accentCustomA11y.
  ///
  /// In id, this message translates to:
  /// **'Warna kustom, pilih sendiri'**
  String get accentCustomA11y;

  /// No description provided for @accentCustomHint.
  ///
  /// In id, this message translates to:
  /// **'Kustom {hex} · ketuk Kustom lagi untuk mengubah. Warna pemasukan dan pengeluaran tetap.'**
  String accentCustomHint(String hex);

  /// No description provided for @accentCustomTitle.
  ///
  /// In id, this message translates to:
  /// **'Warna kustom'**
  String get accentCustomTitle;

  /// No description provided for @accentCustomSub.
  ///
  /// In id, this message translates to:
  /// **'Geser untuk memilih, atau ketik kode hex.'**
  String get accentCustomSub;

  /// No description provided for @accentHue.
  ///
  /// In id, this message translates to:
  /// **'Warna'**
  String get accentHue;

  /// No description provided for @accentSaturation.
  ///
  /// In id, this message translates to:
  /// **'Kepekatan'**
  String get accentSaturation;

  /// No description provided for @accentLightness.
  ///
  /// In id, this message translates to:
  /// **'Kecerahan'**
  String get accentLightness;

  /// No description provided for @accentHexLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode hex'**
  String get accentHexLabel;

  /// No description provided for @accentHexError.
  ///
  /// In id, this message translates to:
  /// **'Format: #RRGGBB, mis. #1F5F4E'**
  String get accentHexError;

  /// No description provided for @accentRecent.
  ///
  /// In id, this message translates to:
  /// **'Terakhir dipakai'**
  String get accentRecent;

  /// No description provided for @accentPreviewChip.
  ///
  /// In id, this message translates to:
  /// **'Terpilih'**
  String get accentPreviewChip;

  /// No description provided for @accentNoteGrey.
  ///
  /// In id, this message translates to:
  /// **'Warna ini hampir abu-abu, jadi aksen kurang menonjol dibanding warna lain.'**
  String get accentNoteGrey;

  /// No description provided for @accentNoteLight.
  ///
  /// In id, this message translates to:
  /// **'Warna cukup terang. Di mode terang tombol dibuat sedikit lebih gelap supaya teksnya tetap terbaca.'**
  String get accentNoteLight;

  /// No description provided for @accentNoteDark.
  ///
  /// In id, this message translates to:
  /// **'Warna sangat gelap. Di mode terang tombol dibuat sedikit lebih terang supaya tetap terlihat berwarna.'**
  String get accentNoteDark;

  /// No description provided for @accentApply.
  ///
  /// In id, this message translates to:
  /// **'Pakai warna'**
  String get accentApply;

  /// No description provided for @currency.
  ///
  /// In id, this message translates to:
  /// **'Mata uang'**
  String get currency;

  /// No description provided for @currencyValue.
  ///
  /// In id, this message translates to:
  /// **'Rupiah (IDR)'**
  String get currencyValue;

  /// No description provided for @versionLabel.
  ///
  /// In id, this message translates to:
  /// **'Nyawtat · versi {version}'**
  String versionLabel(String version);

  /// No description provided for @walletName.
  ///
  /// In id, this message translates to:
  /// **'Nama dompet'**
  String get walletName;

  /// No description provided for @walletNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: BCA, GoPay'**
  String get walletNameHint;

  /// No description provided for @walletType.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get walletType;

  /// No description provided for @walletTypeCash.
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get walletTypeCash;

  /// No description provided for @walletTypeBank.
  ///
  /// In id, this message translates to:
  /// **'Bank'**
  String get walletTypeBank;

  /// No description provided for @walletTypeEwallet.
  ///
  /// In id, this message translates to:
  /// **'E-wallet'**
  String get walletTypeEwallet;

  /// No description provided for @walletTypeOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get walletTypeOther;

  /// No description provided for @openingBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo awal'**
  String get openingBalance;

  /// No description provided for @walletNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Isi nama dompet dulu ya.'**
  String get walletNameRequired;

  /// No description provided for @editWallet.
  ///
  /// In id, this message translates to:
  /// **'Ubah dompet'**
  String get editWallet;

  /// No description provided for @deleteWallet.
  ///
  /// In id, this message translates to:
  /// **'Hapus dompet'**
  String get deleteWallet;

  /// No description provided for @deleteWalletConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus dompet {name}?'**
  String deleteWalletConfirm(String name);

  /// No description provided for @deleteWalletTxWarning.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi di dompet ini juga ikut terhapus.'**
  String deleteWalletTxWarning(int count);

  /// No description provided for @lastWalletCantDelete.
  ///
  /// In id, this message translates to:
  /// **'Dompet terakhir tidak bisa dihapus.'**
  String get lastWalletCantDelete;

  /// No description provided for @catFood.
  ///
  /// In id, this message translates to:
  /// **'Makan'**
  String get catFood;

  /// No description provided for @catTransport.
  ///
  /// In id, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catShopping.
  ///
  /// In id, this message translates to:
  /// **'Belanja'**
  String get catShopping;

  /// No description provided for @catBills.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get catBills;

  /// No description provided for @catEntertainment.
  ///
  /// In id, this message translates to:
  /// **'Hiburan'**
  String get catEntertainment;

  /// No description provided for @catOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get catOther;

  /// No description provided for @catSalary.
  ///
  /// In id, this message translates to:
  /// **'Gaji'**
  String get catSalary;

  /// No description provided for @catBonus.
  ///
  /// In id, this message translates to:
  /// **'Bonus'**
  String get catBonus;

  /// No description provided for @catOtherIncome.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get catOtherIncome;

  /// No description provided for @moodAwful.
  ///
  /// In id, this message translates to:
  /// **'Buruk'**
  String get moodAwful;

  /// No description provided for @moodBad.
  ///
  /// In id, this message translates to:
  /// **'Kurang'**
  String get moodBad;

  /// No description provided for @moodOkay.
  ///
  /// In id, this message translates to:
  /// **'Biasa'**
  String get moodOkay;

  /// No description provided for @moodGood.
  ///
  /// In id, this message translates to:
  /// **'Baik'**
  String get moodGood;

  /// No description provided for @moodGreat.
  ///
  /// In id, this message translates to:
  /// **'Senang'**
  String get moodGreat;

  /// No description provided for @journalEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada entri jurnal. Mulai tulis cerita pertamamu.'**
  String get journalEmpty;

  /// No description provided for @showAllEntries.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan semua'**
  String get showAllEntries;

  /// No description provided for @journalDayEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada entri'**
  String get journalDayEmptyTitle;

  /// No description provided for @journalDayEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada catatan di tanggal ini.'**
  String get journalDayEmptyBody;

  /// No description provided for @writeForThisDay.
  ///
  /// In id, this message translates to:
  /// **'Tulis di tanggal ini'**
  String get writeForThisDay;

  /// No description provided for @prevWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu sebelumnya'**
  String get prevWeek;

  /// No description provided for @nextWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu berikutnya'**
  String get nextWeek;

  /// No description provided for @dayMoodSummary.
  ///
  /// In id, this message translates to:
  /// **'Mood {mood}'**
  String dayMoodSummary(String mood);

  /// No description provided for @noSpending.
  ///
  /// In id, this message translates to:
  /// **'tanpa pengeluaran'**
  String get noSpending;

  /// No description provided for @untitled.
  ///
  /// In id, this message translates to:
  /// **'Tanpa judul'**
  String get untitled;

  /// No description provided for @newEntryTitle.
  ///
  /// In id, this message translates to:
  /// **'Tulis Entri'**
  String get newEntryTitle;

  /// No description provided for @editEntryTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Entri'**
  String get editEntryTitle;

  /// No description provided for @entryTime.
  ///
  /// In id, this message translates to:
  /// **'Jam kejadian'**
  String get entryTime;

  /// No description provided for @optional.
  ///
  /// In id, this message translates to:
  /// **'(opsional)'**
  String get optional;

  /// No description provided for @now.
  ///
  /// In id, this message translates to:
  /// **'Sekarang'**
  String get now;

  /// No description provided for @clearTime.
  ///
  /// In id, this message translates to:
  /// **'Hapus jam'**
  String get clearTime;

  /// No description provided for @pickTime.
  ///
  /// In id, this message translates to:
  /// **'Pilih jam'**
  String get pickTime;

  /// No description provided for @mood.
  ///
  /// In id, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @entryTitle.
  ///
  /// In id, this message translates to:
  /// **'Judul'**
  String get entryTitle;

  /// No description provided for @entryTitleHint.
  ///
  /// In id, this message translates to:
  /// **'Satu kalimat tentang kejadian ini'**
  String get entryTitleHint;

  /// No description provided for @story.
  ///
  /// In id, this message translates to:
  /// **'Cerita'**
  String get story;

  /// No description provided for @storyHint.
  ///
  /// In id, this message translates to:
  /// **'Apa yang terjadi? Apa yang kamu rasakan?'**
  String get storyHint;

  /// No description provided for @tags.
  ///
  /// In id, this message translates to:
  /// **'Tag'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In id, this message translates to:
  /// **'Pisahkan dengan koma, mis. teman, kerja'**
  String get tagsHint;

  /// No description provided for @dayTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi di hari ini'**
  String get dayTransactions;

  /// No description provided for @linkedByDate.
  ///
  /// In id, this message translates to:
  /// **'Otomatis terhubung lewat tanggal.'**
  String get linkedByDate;

  /// No description provided for @entryEmptyError.
  ///
  /// In id, this message translates to:
  /// **'Tulis judul atau cerita dulu ya.'**
  String get entryEmptyError;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus entri ini?'**
  String get deleteEntryConfirm;

  /// No description provided for @moodSpending.
  ///
  /// In id, this message translates to:
  /// **'Mood & pengeluaran'**
  String get moodSpending;

  /// No description provided for @avgGoodMood.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata saat mood baik'**
  String get avgGoodMood;

  /// No description provided for @avgLowMood.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata saat mood kurang'**
  String get avgLowMood;

  /// No description provided for @noData.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data'**
  String get noData;

  /// No description provided for @insightNeedMore.
  ///
  /// In id, this message translates to:
  /// **'Tulis jurnal dengan mood beberapa hari lagi untuk melihat polanya.'**
  String get insightNeedMore;

  /// No description provided for @insightSpendWhenLow.
  ///
  /// In id, this message translates to:
  /// **'Kamu cenderung belanja lebih banyak saat harimu kurang baik. Coba tunda belanja impulsif di hari-hari berat.'**
  String get insightSpendWhenLow;

  /// No description provided for @insightSpendWhenGood.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu lebih besar di hari yang menyenangkan.'**
  String get insightSpendWhenGood;

  /// No description provided for @budget.
  ///
  /// In id, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @budgetPerCategory.
  ///
  /// In id, this message translates to:
  /// **'Budget per kategori'**
  String get budgetPerCategory;

  /// No description provided for @manage.
  ///
  /// In id, this message translates to:
  /// **'Atur'**
  String get manage;

  /// No description provided for @budgetUsage.
  ///
  /// In id, this message translates to:
  /// **'Budget {month} terpakai {pct}% · sisa {left}'**
  String budgetUsage(String month, int pct, String left);

  /// No description provided for @budgetUsedPct.
  ///
  /// In id, this message translates to:
  /// **'{pct}% terpakai'**
  String budgetUsedPct(int pct);

  /// No description provided for @widgetBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo'**
  String get widgetBalance;

  /// No description provided for @widgetTodayOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar hari ini'**
  String get widgetTodayOut;

  /// No description provided for @widgetTodaySuffix.
  ///
  /// In id, this message translates to:
  /// **'keluar hari ini'**
  String get widgetTodaySuffix;

  /// No description provided for @widgetJournalTitle.
  ///
  /// In id, this message translates to:
  /// **'Jurnal hari ini'**
  String get widgetJournalTitle;

  /// No description provided for @widgetJournalSummary.
  ///
  /// In id, this message translates to:
  /// **'{count} entri · terakhir {time}'**
  String widgetJournalSummary(int count, String time);

  /// No description provided for @widgetJournalEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Gimana harimu?'**
  String get widgetJournalEmptyTitle;

  /// No description provided for @widgetJournalEmptySub.
  ///
  /// In id, this message translates to:
  /// **'Belum ada cerita hari ini'**
  String get widgetJournalEmptySub;

  /// No description provided for @widgetBudgetOver.
  ///
  /// In id, this message translates to:
  /// **'Budget {month} lewat {amount}'**
  String widgetBudgetOver(String month, String amount);

  /// No description provided for @overBudget.
  ///
  /// In id, this message translates to:
  /// **'Lewat budget {amount}'**
  String overBudget(String amount);

  /// No description provided for @noBudget.
  ///
  /// In id, this message translates to:
  /// **'Tanpa budget'**
  String get noBudget;

  /// No description provided for @budgetLimit.
  ///
  /// In id, this message translates to:
  /// **'Batas per bulan'**
  String get budgetLimit;

  /// No description provided for @budgetHint.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan untuk tanpa budget'**
  String get budgetHint;

  /// No description provided for @budgetAppliesFrom.
  ///
  /// In id, this message translates to:
  /// **'Berlaku mulai {month} dan bulan-bulan berikutnya.'**
  String budgetAppliesFrom(String month);

  /// No description provided for @budgetSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Atur batas pengeluaran bulanan per kategori'**
  String get budgetSubtitle;

  /// No description provided for @budgetTotal.
  ///
  /// In id, this message translates to:
  /// **'Total budget'**
  String get budgetTotal;

  /// No description provided for @data.
  ///
  /// In id, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @account.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get account;

  /// No description provided for @signInPrompt.
  ///
  /// In id, this message translates to:
  /// **'Masuk supaya data tersimpan di server dan bisa dipakai di beberapa perangkat.'**
  String get signInPrompt;

  /// No description provided for @signIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get signIn;

  /// No description provided for @register.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get register;

  /// No description provided for @signOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In id, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In id, this message translates to:
  /// **'Minimal 8 karakter'**
  String get passwordHint;

  /// No description provided for @errConfirmEmail.
  ///
  /// In id, this message translates to:
  /// **'Cek email kamu dan klik link konfirmasi, lalu masuk.'**
  String get errConfirmEmail;

  /// No description provided for @backendNotConfigured.
  ///
  /// In id, this message translates to:
  /// **'Sinkronisasi belum diatur di build ini.'**
  String get backendNotConfigured;

  /// No description provided for @exportBackup.
  ///
  /// In id, this message translates to:
  /// **'Ekspor backup'**
  String get exportBackup;

  /// No description provided for @exportBackupSub.
  ///
  /// In id, this message translates to:
  /// **'Semua data dalam satu file JSON'**
  String get exportBackupSub;

  /// No description provided for @exportExcel.
  ///
  /// In id, this message translates to:
  /// **'Ekspor ke Excel'**
  String get exportExcel;

  /// No description provided for @exportExcelSub.
  ///
  /// In id, this message translates to:
  /// **'Transaksi, jurnal, dompet, dan budget dalam satu file .xlsx'**
  String get exportExcelSub;

  /// No description provided for @sheetTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get sheetTransactions;

  /// No description provided for @currentBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo sekarang'**
  String get currentBalance;

  /// No description provided for @spent.
  ///
  /// In id, this message translates to:
  /// **'Terpakai'**
  String get spent;

  /// No description provided for @remaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa'**
  String get remaining;

  /// No description provided for @importBackup.
  ///
  /// In id, this message translates to:
  /// **'Impor backup'**
  String get importBackup;

  /// No description provided for @importBackupSub.
  ///
  /// In id, this message translates to:
  /// **'Pulihkan data dari file backup'**
  String get importBackupSub;

  /// No description provided for @importConfirm.
  ///
  /// In id, this message translates to:
  /// **'Impor {file}?'**
  String importConfirm(String file);

  /// No description provided for @importConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Isi file digabung dengan data yang ada. Tidak ada yang dihapus; kalau ada data yang sama, versi yang lebih baru yang dipakai.'**
  String get importConfirmBody;

  /// No description provided for @importAction.
  ///
  /// In id, this message translates to:
  /// **'Impor'**
  String get importAction;

  /// No description provided for @importDone.
  ///
  /// In id, this message translates to:
  /// **'{imported} data diimpor, {skipped} sudah ada'**
  String importDone(int imported, int skipped);

  /// No description provided for @importInvalid.
  ///
  /// In id, this message translates to:
  /// **'File ini bukan backup Nyawtat yang valid.'**
  String get importInvalid;

  /// No description provided for @exportFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengekspor data.'**
  String get exportFailed;

  /// No description provided for @security.
  ///
  /// In id, this message translates to:
  /// **'Keamanan'**
  String get security;

  /// No description provided for @lockWithPin.
  ///
  /// In id, this message translates to:
  /// **'Kunci dengan PIN'**
  String get lockWithPin;

  /// No description provided for @lockWithPinSub.
  ///
  /// In id, this message translates to:
  /// **'Minta PIN saat app dibuka'**
  String get lockWithPinSub;

  /// No description provided for @unlockWithBiometric.
  ///
  /// In id, this message translates to:
  /// **'Buka dengan biometrik'**
  String get unlockWithBiometric;

  /// No description provided for @unlockWithBiometricSub.
  ///
  /// In id, this message translates to:
  /// **'Sidik jari atau wajah'**
  String get unlockWithBiometricSub;

  /// No description provided for @biometricUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Tidak tersedia di perangkat ini'**
  String get biometricUnavailable;

  /// No description provided for @lockNow.
  ///
  /// In id, this message translates to:
  /// **'Kunci aplikasi sekarang'**
  String get lockNow;

  /// No description provided for @hideAmounts.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan nominal'**
  String get hideAmounts;

  /// No description provided for @hideAmountsSub.
  ///
  /// In id, this message translates to:
  /// **'Samarkan saldo dan nominal uang di seluruh aplikasi'**
  String get hideAmountsSub;

  /// No description provided for @enterPin.
  ///
  /// In id, this message translates to:
  /// **'Masukkan PIN untuk membuka'**
  String get enterPin;

  /// No description provided for @wrongPin.
  ///
  /// In id, this message translates to:
  /// **'PIN salah'**
  String get wrongPin;

  /// No description provided for @tooManyAttempts.
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan. Coba lagi dalam {seconds} detik.'**
  String tooManyAttempts(int seconds);

  /// No description provided for @useBiometric.
  ///
  /// In id, this message translates to:
  /// **'Pakai biometrik'**
  String get useBiometric;

  /// No description provided for @biometricReason.
  ///
  /// In id, this message translates to:
  /// **'Buka Nyawtat'**
  String get biometricReason;

  /// No description provided for @forgotPin.
  ///
  /// In id, this message translates to:
  /// **'Lupa PIN?'**
  String get forgotPin;

  /// No description provided for @forgotPinTitle.
  ///
  /// In id, this message translates to:
  /// **'Reset PIN?'**
  String get forgotPinTitle;

  /// No description provided for @forgotPinBody.
  ///
  /// In id, this message translates to:
  /// **'Kamu akan keluar dari akun dan data di HP ini dihapus. Data yang sudah tersinkron tetap aman di server dan kembali saat kamu masuk lagi.'**
  String get forgotPinBody;

  /// No description provided for @forgotPinBodyLocal.
  ///
  /// In id, this message translates to:
  /// **'Semua data di HP ini akan dihapus permanen karena kamu belum masuk ke akun (belum ada salinan di server).'**
  String get forgotPinBodyLocal;

  /// No description provided for @resetPin.
  ///
  /// In id, this message translates to:
  /// **'Reset'**
  String get resetPin;

  /// No description provided for @createPin.
  ///
  /// In id, this message translates to:
  /// **'Buat PIN'**
  String get createPin;

  /// No description provided for @createPinHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih 4 angka yang mudah kamu ingat'**
  String get createPinHint;

  /// No description provided for @confirmPin.
  ///
  /// In id, this message translates to:
  /// **'Ulangi PIN'**
  String get confirmPin;

  /// No description provided for @confirmPinHint.
  ///
  /// In id, this message translates to:
  /// **'Ketik PIN yang sama sekali lagi'**
  String get confirmPinHint;

  /// No description provided for @pinMismatch.
  ///
  /// In id, this message translates to:
  /// **'PIN tidak sama. Ulangi dari awal.'**
  String get pinMismatch;

  /// No description provided for @currentPin.
  ///
  /// In id, this message translates to:
  /// **'PIN saat ini'**
  String get currentPin;

  /// No description provided for @currentPinHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan PIN untuk melanjutkan'**
  String get currentPinHint;

  /// No description provided for @deleteDigit.
  ///
  /// In id, this message translates to:
  /// **'Hapus digit'**
  String get deleteDigit;

  /// No description provided for @transfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @csvDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get csvDate;

  /// No description provided for @csvTime.
  ///
  /// In id, this message translates to:
  /// **'Jam'**
  String get csvTime;

  /// No description provided for @csvType.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get csvType;

  /// No description provided for @csvToWallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet tujuan'**
  String get csvToWallet;

  /// No description provided for @haveAccount.
  ///
  /// In id, this message translates to:
  /// **'Sudah punya akun? Masuk'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In id, this message translates to:
  /// **'Belum punya akun? Daftar'**
  String get noAccount;

  /// No description provided for @syncNow.
  ///
  /// In id, this message translates to:
  /// **'Sinkronkan'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In id, this message translates to:
  /// **'Menyinkronkan…'**
  String get syncing;

  /// No description provided for @lastSynced.
  ///
  /// In id, this message translates to:
  /// **'Terakhir sinkron: {time}'**
  String lastSynced(String time);

  /// No description provided for @neverSynced.
  ///
  /// In id, this message translates to:
  /// **'Belum pernah sinkron'**
  String get neverSynced;

  /// No description provided for @signOutConfirm.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari akun?'**
  String get signOutConfirm;

  /// No description provided for @signOutBody.
  ///
  /// In id, this message translates to:
  /// **'Data di perangkat ini akan dihapus. Data yang sudah tersinkron tetap aman di server dan kembali saat kamu masuk lagi.'**
  String get signOutBody;

  /// No description provided for @signOutUnsynced.
  ///
  /// In id, this message translates to:
  /// **'Ada perubahan yang belum tersinkron dan akan hilang kalau kamu keluar sekarang.'**
  String get signOutUnsynced;

  /// No description provided for @errNetwork.
  ///
  /// In id, this message translates to:
  /// **'Tidak bisa terhubung ke server. Cek alamat server dan koneksi.'**
  String get errNetwork;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In id, this message translates to:
  /// **'Email atau password salah.'**
  String get errInvalidCredentials;

  /// No description provided for @errEmailTaken.
  ///
  /// In id, this message translates to:
  /// **'Email ini sudah terdaftar. Coba masuk.'**
  String get errEmailTaken;

  /// No description provided for @errInvalidEmail.
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid.'**
  String get errInvalidEmail;

  /// No description provided for @errPasswordTooShort.
  ///
  /// In id, this message translates to:
  /// **'Password minimal 8 karakter.'**
  String get errPasswordTooShort;

  /// No description provided for @errSessionExpired.
  ///
  /// In id, this message translates to:
  /// **'Sesi berakhir. Silakan masuk lagi.'**
  String get errSessionExpired;

  /// No description provided for @errServer.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan di server. Coba lagi nanti.'**
  String get errServer;

  /// No description provided for @mascotTodayEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Hai! Hari ini masih kosong'**
  String get mascotTodayEmptyTitle;

  /// No description provided for @mascotJournalEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada catatan'**
  String get mascotJournalEmptyTitle;

  /// No description provided for @mascotJournalEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Tulis sedikit tentang harimu: mood, cerita, atau pengeluaran.'**
  String get mascotJournalEmptyBody;

  /// No description provided for @mascotWriteEntry.
  ///
  /// In id, this message translates to:
  /// **'Tulis catatan'**
  String get mascotWriteEntry;

  /// No description provided for @mascotTxEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi'**
  String get mascotTxEmptyTitle;

  /// No description provided for @mascotTxEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Catat pemasukan atau pengeluaran pertamamu.'**
  String get mascotTxEmptyBody;

  /// No description provided for @mascotRecordTx.
  ///
  /// In id, this message translates to:
  /// **'Catat transaksi'**
  String get mascotRecordTx;

  /// No description provided for @mascotFilterEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Tidak ketemu'**
  String get mascotFilterEmptyTitle;

  /// No description provided for @mascotFilterEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi untuk filter ini.'**
  String get mascotFilterEmptyBody;

  /// No description provided for @mascotReportEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data bulan ini'**
  String get mascotReportEmptyTitle;

  /// No description provided for @mascotReportEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Laporan muncul setelah kamu mencatat pengeluaran.'**
  String get mascotReportEmptyBody;

  /// No description provided for @mascotNoBudgetTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada budget'**
  String get mascotNoBudgetTitle;

  /// No description provided for @mascotNoBudgetBody.
  ///
  /// In id, this message translates to:
  /// **'Atur budget supaya pengeluaranmu terpantau.'**
  String get mascotNoBudgetBody;

  /// No description provided for @mascotBudgetOkTitle.
  ///
  /// In id, this message translates to:
  /// **'Semua budget masih aman'**
  String get mascotBudgetOkTitle;

  /// No description provided for @mascotBudgetOkBody.
  ///
  /// In id, this message translates to:
  /// **'Pertahankan sampai akhir bulan!'**
  String get mascotBudgetOkBody;

  /// No description provided for @mascotBudgetOverTitle.
  ///
  /// In id, this message translates to:
  /// **'{count} kategori lewat budget'**
  String mascotBudgetOverTitle(int count);

  /// No description provided for @mascotBudgetOverBody.
  ///
  /// In id, this message translates to:
  /// **'{names}. Coba rem sedikit, ya.'**
  String mascotBudgetOverBody(String names);

  /// No description provided for @toastEntrySaved.
  ///
  /// In id, this message translates to:
  /// **'Catatan tersimpan'**
  String get toastEntrySaved;

  /// No description provided for @toastEntryUpdated.
  ///
  /// In id, this message translates to:
  /// **'Catatan diperbarui'**
  String get toastEntryUpdated;

  /// No description provided for @toastTxSaved.
  ///
  /// In id, this message translates to:
  /// **'Transaksi tersimpan'**
  String get toastTxSaved;

  /// No description provided for @toastBudgetOver.
  ///
  /// In id, this message translates to:
  /// **'Budget {category} terlewati'**
  String toastBudgetOver(String category);

  /// No description provided for @toastSynced.
  ///
  /// In id, this message translates to:
  /// **'Sinkron selesai'**
  String get toastSynced;

  /// No description provided for @importMm.
  ///
  /// In id, this message translates to:
  /// **'Impor dari Money Manager'**
  String get importMm;

  /// No description provided for @importMmSub.
  ///
  /// In id, this message translates to:
  /// **'File cadangan .mmbak atau ekspor .xlsx dari Money Manager (Realbyte)'**
  String get importMmSub;

  /// No description provided for @importMmReading.
  ///
  /// In id, this message translates to:
  /// **'Membaca file…'**
  String get importMmReading;

  /// No description provided for @importMmNew.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi baru'**
  String importMmNew(int count);

  /// No description provided for @importMmBreakdown.
  ///
  /// In id, this message translates to:
  /// **'{expense} pengeluaran · {income} pemasukan · {transfer} transfer'**
  String importMmBreakdown(int expense, int income, int transfer);

  /// No description provided for @importMmPeriod.
  ///
  /// In id, this message translates to:
  /// **'Periode: {from} – {to}'**
  String importMmPeriod(String from, String to);

  /// No description provided for @importMmAlready.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi sudah pernah diimpor, dilewati.'**
  String importMmAlready(int count);

  /// No description provided for @importMmSkipped.
  ///
  /// In id, this message translates to:
  /// **'{count} transfer ke dompet yang sama dilewati.'**
  String importMmSkipped(int count);

  /// No description provided for @importMmAdjust.
  ///
  /// In id, this message translates to:
  /// **'{count} baris \"Edit saldo\" dimasukkan ke saldo awal dompet.'**
  String importMmAdjust(int count);

  /// No description provided for @importMmWallets.
  ///
  /// In id, this message translates to:
  /// **'Dompet'**
  String get importMmWallets;

  /// No description provided for @importMmNewWallet.
  ///
  /// In id, this message translates to:
  /// **'dompet baru'**
  String get importMmNewWallet;

  /// No description provided for @importMmNewCategories.
  ///
  /// In id, this message translates to:
  /// **'Kategori baru ({count})'**
  String importMmNewCategories(int count);

  /// No description provided for @importMmOverlap.
  ///
  /// In id, this message translates to:
  /// **'Transaksi yang kamu catat sendiri di Nyawtat tidak dicocokkan. Setelah impor, cek tanggal yang tumpang tindih supaya tidak dobel.'**
  String get importMmOverlap;

  /// No description provided for @importMmNothing.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data baru di file ini.'**
  String get importMmNothing;

  /// No description provided for @importMmDone.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi diimpor'**
  String importMmDone(int count);

  /// No description provided for @importMmInvalid.
  ///
  /// In id, this message translates to:
  /// **'File tidak dikenali sebagai data Money Manager.'**
  String get importMmInvalid;

  /// No description provided for @archiveWallet.
  ///
  /// In id, this message translates to:
  /// **'Arsipkan dompet'**
  String get archiveWallet;

  /// No description provided for @unarchiveWallet.
  ///
  /// In id, this message translates to:
  /// **'Keluarkan dari arsip'**
  String get unarchiveWallet;

  /// No description provided for @archiveWalletHint.
  ///
  /// In id, this message translates to:
  /// **'Dompet arsip tidak tampil di daftar dan total saldo, tapi transaksinya tetap ada di riwayat dan laporan.'**
  String get archiveWalletHint;

  /// No description provided for @archivedWalletsCard.
  ///
  /// In id, this message translates to:
  /// **'Arsip ({count})'**
  String archivedWalletsCard(int count);

  /// No description provided for @archivedWalletsTitle.
  ///
  /// In id, this message translates to:
  /// **'Dompet diarsipkan'**
  String get archivedWalletsTitle;

  /// No description provided for @walletArchivedBadge.
  ///
  /// In id, this message translates to:
  /// **'Diarsipkan'**
  String get walletArchivedBadge;

  /// No description provided for @toastWalletArchived.
  ///
  /// In id, this message translates to:
  /// **'Dompet diarsipkan'**
  String get toastWalletArchived;

  /// No description provided for @toastWalletUnarchived.
  ///
  /// In id, this message translates to:
  /// **'Dompet dikeluarkan dari arsip'**
  String get toastWalletUnarchived;

  /// No description provided for @importMmArchived.
  ///
  /// In id, this message translates to:
  /// **'diarsipkan'**
  String get importMmArchived;

  /// No description provided for @importMmMoved.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi yang sudah diimpor dipindah ke dompet yang benar.'**
  String importMmMoved(int count);

  /// No description provided for @currentBalanceHint.
  ///
  /// In id, this message translates to:
  /// **'Kalau saldo diubah, selisihnya dicatat sebagai transaksi Lainnya.'**
  String get currentBalanceHint;

  /// No description provided for @balanceAdjustmentNote.
  ///
  /// In id, this message translates to:
  /// **'Penyesuaian saldo'**
  String get balanceAdjustmentNote;

  /// No description provided for @manageWallets.
  ///
  /// In id, this message translates to:
  /// **'Kelola dompet'**
  String get manageWallets;

  /// No description provided for @manageAction.
  ///
  /// In id, this message translates to:
  /// **'Kelola'**
  String get manageAction;

  /// No description provided for @activeWallets.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get activeWallets;

  /// No description provided for @walletsTotal.
  ///
  /// In id, this message translates to:
  /// **'Total saldo {count} dompet aktif'**
  String walletsTotal(int count);

  /// No description provided for @walletTxCount.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi'**
  String walletTxCount(int count);

  /// No description provided for @archivedWalletLine.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi · saldo {amount}'**
  String archivedWalletLine(int count, String amount);

  /// No description provided for @unarchiveShort.
  ///
  /// In id, this message translates to:
  /// **'Keluarkan'**
  String get unarchiveShort;

  /// No description provided for @manageCategories.
  ///
  /// In id, this message translates to:
  /// **'Kelola kategori'**
  String get manageCategories;

  /// No description provided for @categoriesSub.
  ///
  /// In id, this message translates to:
  /// **'Urutkan, sembunyikan, atau gabungkan kategori'**
  String get categoriesSub;

  /// No description provided for @categoryReorderHint.
  ///
  /// In id, this message translates to:
  /// **'Tahan pegangan di kiri lalu geser untuk mengubah urutan. Urutan ini juga dipakai di form catat transaksi.'**
  String get categoryReorderHint;

  /// No description provided for @categorySystemBadge.
  ///
  /// In id, this message translates to:
  /// **'bawaan'**
  String get categorySystemBadge;

  /// No description provided for @categoryBudgetMeta.
  ///
  /// In id, this message translates to:
  /// **'budget {amount}'**
  String categoryBudgetMeta(String amount);

  /// No description provided for @hiddenCategoriesTitle.
  ///
  /// In id, this message translates to:
  /// **'Disembunyikan ({count})'**
  String hiddenCategoriesTitle(int count);

  /// No description provided for @hiddenCategoriesHint.
  ///
  /// In id, this message translates to:
  /// **'Tidak muncul di form catat transaksi. Transaksi lamanya tetap memakai kategori ini.'**
  String get hiddenCategoriesHint;

  /// No description provided for @noHiddenCategories.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kategori yang disembunyikan.'**
  String get noHiddenCategories;

  /// No description provided for @showCategory.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan'**
  String get showCategory;

  /// No description provided for @newExpenseCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori pengeluaran baru'**
  String get newExpenseCategory;

  /// No description provided for @newIncomeCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori pemasukan baru'**
  String get newIncomeCategory;

  /// No description provided for @editCategory.
  ///
  /// In id, this message translates to:
  /// **'Ubah kategori'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In id, this message translates to:
  /// **'Nama kategori'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Kuota, Admin bank'**
  String get categoryNameHint;

  /// No description provided for @categoryNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Isi nama kategori dulu ya.'**
  String get categoryNameRequired;

  /// No description provided for @systemCategoryNameNote.
  ///
  /// In id, this message translates to:
  /// **'Nama kategori bawaan mengikuti bahasa app.'**
  String get systemCategoryNameNote;

  /// No description provided for @categoryColor.
  ///
  /// In id, this message translates to:
  /// **'Warna'**
  String get categoryColor;

  /// No description provided for @hideFromForm.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan dari form'**
  String get hideFromForm;

  /// No description provided for @showInForm.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan lagi di form'**
  String get showInForm;

  /// No description provided for @mergeCategory.
  ///
  /// In id, this message translates to:
  /// **'Gabungkan ke kategori lain…'**
  String get mergeCategory;

  /// No description provided for @mergeCategoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Gabungkan {name} ke…'**
  String mergeCategoryTitle(String name);

  /// No description provided for @mergeCategoryHint.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi akan dipindah, lalu kategori {name} dihapus.'**
  String mergeCategoryHint(int count, String name);

  /// No description provided for @mergeConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Gabungkan kategori?'**
  String get mergeConfirmTitle;

  /// No description provided for @mergeConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi di {from} akan dipindah ke {to}, lalu {from} dihapus. Ini tidak bisa dibatalkan.'**
  String mergeConfirmBody(int count, String from, String to);

  /// No description provided for @mergeAction.
  ///
  /// In id, this message translates to:
  /// **'Gabungkan'**
  String get mergeAction;

  /// No description provided for @deleteCategory.
  ///
  /// In id, this message translates to:
  /// **'Hapus kategori'**
  String get deleteCategory;

  /// No description provided for @deleteSystemCategoryHint.
  ///
  /// In id, this message translates to:
  /// **'Kategori bawaan tidak bisa dihapus, tapi bisa disembunyikan.'**
  String get deleteSystemCategoryHint;

  /// No description provided for @deleteUsedCategoryHint.
  ///
  /// In id, this message translates to:
  /// **'Masih dipakai {count} transaksi. Gabungkan dulu ke kategori lain.'**
  String deleteUsedCategoryHint(int count);

  /// No description provided for @toastCategorySaved.
  ///
  /// In id, this message translates to:
  /// **'Kategori tersimpan'**
  String get toastCategorySaved;

  /// No description provided for @toastCategoryHidden.
  ///
  /// In id, this message translates to:
  /// **'{name} disembunyikan'**
  String toastCategoryHidden(String name);

  /// No description provided for @toastCategoryShown.
  ///
  /// In id, this message translates to:
  /// **'{name} ditampilkan lagi'**
  String toastCategoryShown(String name);

  /// No description provided for @toastCategoryMerged.
  ///
  /// In id, this message translates to:
  /// **'{from} digabung ke {to}'**
  String toastCategoryMerged(String from, String to);

  /// No description provided for @toastCategoryDeleted.
  ///
  /// In id, this message translates to:
  /// **'Kategori dihapus'**
  String get toastCategoryDeleted;

  /// No description provided for @categoryIcon.
  ///
  /// In id, this message translates to:
  /// **'Ikon'**
  String get categoryIcon;

  /// No description provided for @categoryIconNone.
  ///
  /// In id, this message translates to:
  /// **'Tanpa ikon (huruf awal)'**
  String get categoryIconNone;

  /// No description provided for @iconFood.
  ///
  /// In id, this message translates to:
  /// **'Makan'**
  String get iconFood;

  /// No description provided for @iconCoffee.
  ///
  /// In id, this message translates to:
  /// **'Kopi'**
  String get iconCoffee;

  /// No description provided for @iconCar.
  ///
  /// In id, this message translates to:
  /// **'Mobil'**
  String get iconCar;

  /// No description provided for @iconMotorbike.
  ///
  /// In id, this message translates to:
  /// **'Motor'**
  String get iconMotorbike;

  /// No description provided for @iconShopping.
  ///
  /// In id, this message translates to:
  /// **'Belanja'**
  String get iconShopping;

  /// No description provided for @iconBills.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get iconBills;

  /// No description provided for @iconData.
  ///
  /// In id, this message translates to:
  /// **'Kuota'**
  String get iconData;

  /// No description provided for @iconEntertainment.
  ///
  /// In id, this message translates to:
  /// **'Hiburan'**
  String get iconEntertainment;

  /// No description provided for @iconHealth.
  ///
  /// In id, this message translates to:
  /// **'Kesehatan'**
  String get iconHealth;

  /// No description provided for @iconEducation.
  ///
  /// In id, this message translates to:
  /// **'Pendidikan'**
  String get iconEducation;

  /// No description provided for @iconGift.
  ///
  /// In id, this message translates to:
  /// **'Hadiah'**
  String get iconGift;

  /// No description provided for @iconClothes.
  ///
  /// In id, this message translates to:
  /// **'Pakaian'**
  String get iconClothes;

  /// No description provided for @iconHome.
  ///
  /// In id, this message translates to:
  /// **'Rumah'**
  String get iconHome;

  /// No description provided for @iconFriends.
  ///
  /// In id, this message translates to:
  /// **'Teman'**
  String get iconFriends;

  /// No description provided for @iconCharity.
  ///
  /// In id, this message translates to:
  /// **'Sedekah'**
  String get iconCharity;

  /// No description provided for @iconSalary.
  ///
  /// In id, this message translates to:
  /// **'Gaji'**
  String get iconSalary;

  /// No description provided for @iconSavings.
  ///
  /// In id, this message translates to:
  /// **'Tabungan'**
  String get iconSavings;

  /// No description provided for @iconInvestment.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get iconInvestment;

  /// No description provided for @iconTravel.
  ///
  /// In id, this message translates to:
  /// **'Perjalanan'**
  String get iconTravel;

  /// No description provided for @search.
  ///
  /// In id, this message translates to:
  /// **'Cari'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari jurnal, catatan, kategori, nominal…'**
  String get searchHint;

  /// No description provided for @clearText.
  ///
  /// In id, this message translates to:
  /// **'Hapus teks'**
  String get clearText;

  /// No description provided for @searchScopeAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get searchScopeAll;

  /// No description provided for @searchScopeTx.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get searchScopeTx;

  /// No description provided for @periodAll.
  ///
  /// In id, this message translates to:
  /// **'Semua waktu'**
  String get periodAll;

  /// No description provided for @periodThisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini'**
  String get periodThisMonth;

  /// No description provided for @periodThreeMonths.
  ///
  /// In id, this message translates to:
  /// **'3 bulan'**
  String get periodThreeMonths;

  /// No description provided for @recentSearches.
  ///
  /// In id, this message translates to:
  /// **'Pencarian terakhir'**
  String get recentSearches;

  /// No description provided for @clearRecentSearches.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get clearRecentSearches;

  /// No description provided for @trySearching.
  ///
  /// In id, this message translates to:
  /// **'Coba cari'**
  String get trySearching;

  /// No description provided for @searchCountEntries.
  ///
  /// In id, this message translates to:
  /// **'{count} jurnal'**
  String searchCountEntries(int count);

  /// No description provided for @searchSumOut.
  ///
  /// In id, this message translates to:
  /// **'keluar {amount}'**
  String searchSumOut(String amount);

  /// No description provided for @searchSumIn.
  ///
  /// In id, this message translates to:
  /// **'masuk {amount}'**
  String searchSumIn(String amount);

  /// No description provided for @searchNotFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak ketemu'**
  String get searchNotFound;

  /// No description provided for @searchNotFoundBody.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada jurnal atau transaksi yang cocok dengan \"{query}\".'**
  String searchNotFoundBody(String query);

  /// No description provided for @searchNotFoundPeriodBody.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada jurnal atau transaksi yang cocok dengan \"{query}\" di periode ini.'**
  String searchNotFoundPeriodBody(String query);

  /// No description provided for @voiceNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan suara'**
  String get voiceNote;

  /// No description provided for @recordVoice.
  ///
  /// In id, this message translates to:
  /// **'Rekam suara'**
  String get recordVoice;

  /// No description provided for @recordAgain.
  ///
  /// In id, this message translates to:
  /// **'Rekam ulang'**
  String get recordAgain;

  /// No description provided for @recordingVoice.
  ///
  /// In id, this message translates to:
  /// **'Merekam suara...'**
  String get recordingVoice;

  /// No description provided for @transcription.
  ///
  /// In id, this message translates to:
  /// **'Transkripsi suara'**
  String get transcription;

  /// No description provided for @copyToStory.
  ///
  /// In id, this message translates to:
  /// **'Salin ke cerita'**
  String get copyToStory;

  /// No description provided for @copiedToStory.
  ///
  /// In id, this message translates to:
  /// **'Transkripsi disalin ke cerita'**
  String get copiedToStory;

  /// No description provided for @deleteVoiceConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus rekaman suara ini?'**
  String get deleteVoiceConfirm;

  /// No description provided for @quickAddVoice.
  ///
  /// In id, this message translates to:
  /// **'Catatan suara'**
  String get quickAddVoice;

  /// No description provided for @quickAddVoiceSub.
  ///
  /// In id, this message translates to:
  /// **'Rekam cerita & transkripsi otomatis'**
  String get quickAddVoiceSub;

  /// No description provided for @micPermissionRequired.
  ///
  /// In id, this message translates to:
  /// **'Izin mikrofon diperlukan untuk merekam suara.'**
  String get micPermissionRequired;

  /// No description provided for @chartDistribution.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get chartDistribution;

  /// No description provided for @chartWeekly.
  ///
  /// In id, this message translates to:
  /// **'Mingguan'**
  String get chartWeekly;

  /// No description provided for @chartExpenseAnalysis.
  ///
  /// In id, this message translates to:
  /// **'Analisis Pengeluaran'**
  String get chartExpenseAnalysis;

  /// No description provided for @chartExpenseByCategory.
  ///
  /// In id, this message translates to:
  /// **'Distribusi Kategori'**
  String get chartExpenseByCategory;

  /// No description provided for @chartWeeklyTrend.
  ///
  /// In id, this message translates to:
  /// **'Tren Mingguan'**
  String get chartWeeklyTrend;

  /// No description provided for @chartAllCategories.
  ///
  /// In id, this message translates to:
  /// **'Semua kategori ({count})'**
  String chartAllCategories(int count);

  /// No description provided for @chartShowLess.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan'**
  String get chartShowLess;

  /// No description provided for @chartAvgWeekly.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata/minggu'**
  String get chartAvgWeekly;

  /// No description provided for @chartHighestWeek.
  ///
  /// In id, this message translates to:
  /// **'Tertinggi: M{week}'**
  String chartHighestWeek(int week);

  /// No description provided for @prevMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan sebelumnya'**
  String get prevMonth;

  /// No description provided for @nextMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan berikutnya'**
  String get nextMonth;

  /// No description provided for @thisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini'**
  String get thisMonth;

  /// No description provided for @totalExpense.
  ///
  /// In id, this message translates to:
  /// **'Total Pengeluaran'**
  String get totalExpense;

  /// No description provided for @categoryCount.
  ///
  /// In id, this message translates to:
  /// **'{count} kategori'**
  String categoryCount(int count);

  /// No description provided for @googleDriveBackup.
  ///
  /// In id, this message translates to:
  /// **'Cadangan Google Drive'**
  String get googleDriveBackup;

  /// No description provided for @googleDriveBackupSub.
  ///
  /// In id, this message translates to:
  /// **'Sinkronisasi Cloud otomatis & mandiri'**
  String get googleDriveBackupSub;

  /// No description provided for @googleDriveConnected.
  ///
  /// In id, this message translates to:
  /// **'Terhubung'**
  String get googleDriveConnected;

  /// No description provided for @googleDriveNotConnected.
  ///
  /// In id, this message translates to:
  /// **'Belum terhubung'**
  String get googleDriveNotConnected;

  /// No description provided for @googleDriveConnect.
  ///
  /// In id, this message translates to:
  /// **'Hubungkan Akun Google'**
  String get googleDriveConnect;

  /// No description provided for @googleDriveDisconnect.
  ///
  /// In id, this message translates to:
  /// **'Putuskan Akun'**
  String get googleDriveDisconnect;

  /// No description provided for @googleDriveLastBackup.
  ///
  /// In id, this message translates to:
  /// **'Cadangan terakhir: {time}'**
  String googleDriveLastBackup(String time);

  /// No description provided for @googleDriveNever.
  ///
  /// In id, this message translates to:
  /// **'Belum pernah dicadangkan'**
  String get googleDriveNever;

  /// No description provided for @googleDriveFormatInfo.
  ///
  /// In id, this message translates to:
  /// **'Format: Excel (.xlsx) / Sheets'**
  String get googleDriveFormatInfo;

  /// No description provided for @googleDriveFormatDesc.
  ///
  /// In id, this message translates to:
  /// **'Bisa dibuka langsung di Google Sheets dengan 4 lembar kerja: Transaksi, Jurnal, Dompet, dan Budget.'**
  String get googleDriveFormatDesc;

  /// No description provided for @googleDriveSheetsPreview.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau Sheets'**
  String get googleDriveSheetsPreview;

  /// No description provided for @googleSignIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan Google'**
  String get googleSignIn;

  /// No description provided for @googleSignInPrompt.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan akun Google untuk sinkronisasi otomatis ke Google Drive.'**
  String get googleSignInPrompt;

  /// No description provided for @guestMode.
  ///
  /// In id, this message translates to:
  /// **'Mode Tamu (Offline)'**
  String get guestMode;

  /// No description provided for @guestModePrompt.
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan Google atau Email server untuk mencadangkan data.'**
  String get guestModePrompt;

  /// No description provided for @nyawtatServerConnected.
  ///
  /// In id, this message translates to:
  /// **'Server Nyawtat Terhubung'**
  String get nyawtatServerConnected;

  /// No description provided for @googleDriveConnectedBadge.
  ///
  /// In id, this message translates to:
  /// **'Google Drive Terhubung'**
  String get googleDriveConnectedBadge;

  /// No description provided for @signInAccount.
  ///
  /// In id, this message translates to:
  /// **'Masuk Akun'**
  String get signInAccount;

  /// No description provided for @backupRange.
  ///
  /// In id, this message translates to:
  /// **'Rentang Data Cadangan'**
  String get backupRange;

  /// No description provided for @rangeAll.
  ///
  /// In id, this message translates to:
  /// **'Semua Riwayat'**
  String get rangeAll;

  /// No description provided for @rangeThisYear.
  ///
  /// In id, this message translates to:
  /// **'Tahun Ini'**
  String get rangeThisYear;

  /// No description provided for @rangeThisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan Ini'**
  String get rangeThisMonth;

  /// No description provided for @rangeCustom.
  ///
  /// In id, this message translates to:
  /// **'Rentang Kustom'**
  String get rangeCustom;

  /// No description provided for @rangeCustomFrom.
  ///
  /// In id, this message translates to:
  /// **'Dari'**
  String get rangeCustomFrom;

  /// No description provided for @rangeCustomTo.
  ///
  /// In id, this message translates to:
  /// **'Sampai'**
  String get rangeCustomTo;

  /// No description provided for @backupNow.
  ///
  /// In id, this message translates to:
  /// **'Cadangkan ke Drive'**
  String get backupNow;

  /// No description provided for @backupNowSuccess.
  ///
  /// In id, this message translates to:
  /// **'Berhasil dicadangkan ke Google Drive!'**
  String get backupNowSuccess;

  /// No description provided for @backupNowLoading.
  ///
  /// In id, this message translates to:
  /// **'Mengunggah ke Drive...'**
  String get backupNowLoading;

  /// No description provided for @openInSheets.
  ///
  /// In id, this message translates to:
  /// **'Buka di Sheets'**
  String get openInSheets;

  /// No description provided for @restoreFromDrive.
  ///
  /// In id, this message translates to:
  /// **'Pulihkan dari Drive'**
  String get restoreFromDrive;

  /// No description provided for @restoreFromDriveConfirm.
  ///
  /// In id, this message translates to:
  /// **'Pulihkan data dari cadangan Google Drive? Data lokal akan disinkronkan.'**
  String get restoreFromDriveConfirm;

  /// No description provided for @restoreFromDriveSuccess.
  ///
  /// In id, this message translates to:
  /// **'Data berhasil dipulihkan dari Google Drive!'**
  String get restoreFromDriveSuccess;

  /// No description provided for @localDataTitle.
  ///
  /// In id, this message translates to:
  /// **'Penyimpanan Lokal'**
  String get localDataTitle;

  /// No description provided for @localBackup.
  ///
  /// In id, this message translates to:
  /// **'Cadangkan Data (Ekspor)'**
  String get localBackup;

  /// No description provided for @localBackupSub.
  ///
  /// In id, this message translates to:
  /// **'Simpan file Excel (.xlsx) atau Cadangan (.json) ke HP'**
  String get localBackupSub;

  /// No description provided for @localRestore.
  ///
  /// In id, this message translates to:
  /// **'Pulihkan / Impor Data'**
  String get localRestore;

  /// No description provided for @localRestoreSub.
  ///
  /// In id, this message translates to:
  /// **'Deteksi otomatis file Nyawtat atau Money Manager'**
  String get localRestoreSub;

  /// No description provided for @formatExcel.
  ///
  /// In id, this message translates to:
  /// **'Laporan Excel (.xlsx)'**
  String get formatExcel;

  /// No description provided for @formatExcelDesc.
  ///
  /// In id, this message translates to:
  /// **'Bisa dibuka, dianalisis, dan dicetak di Google Sheets / Microsoft Excel.'**
  String get formatExcelDesc;

  /// No description provided for @formatJson.
  ///
  /// In id, this message translates to:
  /// **'File Cadangan Nyawtat (.json)'**
  String get formatJson;

  /// No description provided for @formatJsonDesc.
  ///
  /// In id, this message translates to:
  /// **'Cadangan lengkap dengan relasi data untuk dipulihkan ke HP lain.'**
  String get formatJsonDesc;

  /// No description provided for @exportAction.
  ///
  /// In id, this message translates to:
  /// **'Ekspor & Bagikan File'**
  String get exportAction;

  /// No description provided for @selectBackupFile.
  ///
  /// In id, this message translates to:
  /// **'Pilih File Cadangan'**
  String get selectBackupFile;

  /// No description provided for @selectBackupFileHint.
  ///
  /// In id, this message translates to:
  /// **'Mendukung .json (Nyawtat) atau .mmbak / .sqlite / .xlsx (Money Manager)'**
  String get selectBackupFileHint;

  /// No description provided for @autoBackupWifi.
  ///
  /// In id, this message translates to:
  /// **'Cadangkan Otomatis'**
  String get autoBackupWifi;

  /// No description provided for @autoBackupWifiSub.
  ///
  /// In id, this message translates to:
  /// **'Saat terhubung ke jaringan Wi-Fi'**
  String get autoBackupWifiSub;

  /// No description provided for @unsupportedFileFormat.
  ///
  /// In id, this message translates to:
  /// **'Format file tidak dikenali. Pilih file backup .json atau file Money Manager.'**
  String get unsupportedFileFormat;

  /// No description provided for @addSubcategory.
  ///
  /// In id, this message translates to:
  /// **'Subkategori'**
  String get addSubcategory;

  /// No description provided for @allOfCategory.
  ///
  /// In id, this message translates to:
  /// **'Semua {name}'**
  String allOfCategory(String name);

  /// No description provided for @subcategoryCount.
  ///
  /// In id, this message translates to:
  /// **'{count} subkategori'**
  String subcategoryCount(int count);

  /// No description provided for @newSubcategory.
  ///
  /// In id, this message translates to:
  /// **'Subkategori baru di {parent}'**
  String newSubcategory(String parent);

  /// No description provided for @editSubcategory.
  ///
  /// In id, this message translates to:
  /// **'Ubah subkategori'**
  String get editSubcategory;

  /// No description provided for @subcategoryColorNote.
  ///
  /// In id, this message translates to:
  /// **'Warna mengikuti kategori {parent}.'**
  String subcategoryColorNote(String parent);

  /// No description provided for @greetingMorning.
  ///
  /// In id, this message translates to:
  /// **'Selamat pagi!'**
  String get greetingMorning;

  /// No description provided for @greetingNoon.
  ///
  /// In id, this message translates to:
  /// **'Selamat siang!'**
  String get greetingNoon;

  /// No description provided for @greetingAfternoon.
  ///
  /// In id, this message translates to:
  /// **'Selamat sore!'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In id, this message translates to:
  /// **'Selamat malam!'**
  String get greetingEvening;

  /// No description provided for @greetingCount.
  ///
  /// In id, this message translates to:
  /// **'Sudah {count} catatan hari ini. Mantap!'**
  String greetingCount(int count);

  /// No description provided for @greetingEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada catatan hari ini. Yuk mulai!'**
  String get greetingEmpty;

  /// No description provided for @journalPromptTitle.
  ///
  /// In id, this message translates to:
  /// **'Pertanyaan hari ini'**
  String get journalPromptTitle;

  /// No description provided for @journalPromptAction.
  ///
  /// In id, this message translates to:
  /// **'Tulis jawaban ›'**
  String get journalPromptAction;

  /// No description provided for @journalPrompt1.
  ///
  /// In id, this message translates to:
  /// **'Apa hal kecil yang bikin kamu senyum hari ini?'**
  String get journalPrompt1;

  /// No description provided for @journalPrompt2.
  ///
  /// In id, this message translates to:
  /// **'Apa yang paling kamu syukuri hari ini?'**
  String get journalPrompt2;

  /// No description provided for @journalPrompt3.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran apa hari ini yang paling worth it?'**
  String get journalPrompt3;

  /// No description provided for @journalPrompt4.
  ///
  /// In id, this message translates to:
  /// **'Apa yang ingin kamu lakukan lebih baik besok?'**
  String get journalPrompt4;

  /// No description provided for @journalPrompt5.
  ///
  /// In id, this message translates to:
  /// **'Siapa yang membuat harimu lebih ringan?'**
  String get journalPrompt5;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In id, this message translates to:
  /// **'Ada versi baru!'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In id, this message translates to:
  /// **'Nyawtat {version} sudah tersedia{size}. Datamu tetap aman saat update.'**
  String updateAvailableBody(String version, String size);

  /// No description provided for @updateDownload.
  ///
  /// In id, this message translates to:
  /// **'Unduh'**
  String get updateDownload;

  /// No description provided for @updateWhatsNew.
  ///
  /// In id, this message translates to:
  /// **'Apa yang baru?'**
  String get updateWhatsNew;

  /// No description provided for @updateLater.
  ///
  /// In id, this message translates to:
  /// **'Nanti saja'**
  String get updateLater;

  /// No description provided for @updateDownloading.
  ///
  /// In id, this message translates to:
  /// **'Mengunduh {version}…'**
  String updateDownloading(String version);

  /// No description provided for @updateDownloadProgress.
  ///
  /// In id, this message translates to:
  /// **'{done} / {total} · app tetap bisa dipakai'**
  String updateDownloadProgress(String done, String total);

  /// No description provided for @updateCancel.
  ///
  /// In id, this message translates to:
  /// **'Batalkan'**
  String get updateCancel;

  /// No description provided for @updateReadyTitle.
  ///
  /// In id, this message translates to:
  /// **'Siap dipasang!'**
  String get updateReadyTitle;

  /// No description provided for @updateReadyBody.
  ///
  /// In id, this message translates to:
  /// **'File sudah dicek keasliannya. Pemasangan cuma butuh beberapa detik.'**
  String get updateReadyBody;

  /// No description provided for @updateInstallNow.
  ///
  /// In id, this message translates to:
  /// **'Pasang sekarang'**
  String get updateInstallNow;

  /// No description provided for @updateWhatsNewTitle.
  ///
  /// In id, this message translates to:
  /// **'Apa yang baru di {version}'**
  String updateWhatsNewTitle(String version);

  /// No description provided for @updateReleased.
  ///
  /// In id, this message translates to:
  /// **'Dirilis {date}'**
  String updateReleased(String date);

  /// No description provided for @updateInstallHint.
  ///
  /// In id, this message translates to:
  /// **'Diunduh di dalam app, lalu Android akan minta konfirmasi pemasangan. Pemasangan pertama minta izin \"Instal aplikasi tak dikenal\" untuk Nyawtat. Datamu tetap aman.'**
  String get updateInstallHint;

  /// No description provided for @updateDownloadAndInstall.
  ///
  /// In id, this message translates to:
  /// **'Unduh & pasang'**
  String get updateDownloadAndInstall;

  /// No description provided for @updateOpenRelease.
  ///
  /// In id, this message translates to:
  /// **'Buka halaman rilis'**
  String get updateOpenRelease;

  /// No description provided for @updateRemindLater.
  ///
  /// In id, this message translates to:
  /// **'Ingatkan nanti'**
  String get updateRemindLater;

  /// No description provided for @updateErrorNetwork.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengunduh. Periksa internet lalu coba lagi.'**
  String get updateErrorNetwork;

  /// No description provided for @updateErrorChecksum.
  ///
  /// In id, this message translates to:
  /// **'File update tidak cocok dengan rilis resmi, jadi tidak dipasang.'**
  String get updateErrorChecksum;

  /// No description provided for @updateErrorPermission.
  ///
  /// In id, this message translates to:
  /// **'Izinkan Nyawtat memasang aplikasi, lalu ketuk Pasang sekarang lagi.'**
  String get updateErrorPermission;

  /// No description provided for @updateErrorSource.
  ///
  /// In id, this message translates to:
  /// **'File update bukan dari rilis resmi Nyawtat.'**
  String get updateErrorSource;

  /// No description provided for @aboutTitle.
  ///
  /// In id, this message translates to:
  /// **'Tentang'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In id, this message translates to:
  /// **'Versi {version} ({build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @updateLastChecked.
  ///
  /// In id, this message translates to:
  /// **'Terakhir dicek: {when}'**
  String updateLastChecked(String when);

  /// No description provided for @updateCheckNow.
  ///
  /// In id, this message translates to:
  /// **'Cek update'**
  String get updateCheckNow;

  /// No description provided for @updateChecking.
  ///
  /// In id, this message translates to:
  /// **'Nyaw sedang mengecek…'**
  String get updateChecking;

  /// No description provided for @updateVersionAvailable.
  ///
  /// In id, this message translates to:
  /// **'Versi {version} tersedia'**
  String updateVersionAvailable(String version);

  /// No description provided for @updateUpToDate.
  ///
  /// In id, this message translates to:
  /// **'Sudah versi terbaru'**
  String get updateUpToDate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengecek. Periksa koneksi internet.'**
  String get updateCheckFailed;

  /// No description provided for @updateAuto.
  ///
  /// In id, this message translates to:
  /// **'Cek update otomatis'**
  String get updateAuto;

  /// No description provided for @updateAutoSub.
  ///
  /// In id, this message translates to:
  /// **'Sekali sehari saat ada internet'**
  String get updateAutoSub;

  /// No description provided for @updatePrivacyNote.
  ///
  /// In id, this message translates to:
  /// **'Nyawtat hanya membaca daftar rilis di GitHub. Tidak ada data pribadi yang dikirim.'**
  String get updatePrivacyNote;

  /// No description provided for @aboutReleases.
  ///
  /// In id, this message translates to:
  /// **'Riwayat versi'**
  String get aboutReleases;

  /// No description provided for @aboutTester.
  ///
  /// In id, this message translates to:
  /// **'Jadi tester'**
  String get aboutTester;

  /// No description provided for @aboutTesterSub.
  ///
  /// In id, this message translates to:
  /// **'Dapat versi baru lebih dulu'**
  String get aboutTesterSub;

  /// No description provided for @updateSnoozed.
  ///
  /// In id, this message translates to:
  /// **'Oke! Nyaw ingatkan lagi besok.'**
  String get updateSnoozed;

  /// No description provided for @games.
  ///
  /// In id, this message translates to:
  /// **'Permainan'**
  String get games;

  /// No description provided for @gamesSub.
  ///
  /// In id, this message translates to:
  /// **'Lagi penat? Rehat sebentar bareng Nyaw.'**
  String get gamesSub;

  /// No description provided for @gameWheel.
  ///
  /// In id, this message translates to:
  /// **'Roda putar'**
  String get gameWheel;

  /// No description provided for @gameRps.
  ///
  /// In id, this message translates to:
  /// **'Batu gunting kertas'**
  String get gameRps;

  /// No description provided for @gameWheelFood.
  ///
  /// In id, this message translates to:
  /// **'Makan apa?'**
  String get gameWheelFood;

  /// No description provided for @gameWheelDrink.
  ///
  /// In id, this message translates to:
  /// **'Minum apa?'**
  String get gameWheelDrink;

  /// No description provided for @gameWheelYesNo.
  ///
  /// In id, this message translates to:
  /// **'Ya / Tidak'**
  String get gameWheelYesNo;

  /// No description provided for @gameWheelActivity.
  ///
  /// In id, this message translates to:
  /// **'Mau ngapain?'**
  String get gameWheelActivity;

  /// No description provided for @gameWheelFoodDefaults.
  ///
  /// In id, this message translates to:
  /// **'Nasi padang|Bakso|Mie ayam|Soto|Ayam geprek|Gado-gado'**
  String get gameWheelFoodDefaults;

  /// No description provided for @gameWheelDrinkDefaults.
  ///
  /// In id, this message translates to:
  /// **'Kopi susu|Es teh|Jus alpukat|Air putih'**
  String get gameWheelDrinkDefaults;

  /// No description provided for @gameWheelYesNoDefaults.
  ///
  /// In id, this message translates to:
  /// **'Ya|Tidak'**
  String get gameWheelYesNoDefaults;

  /// No description provided for @gameWheelActivityDefaults.
  ///
  /// In id, this message translates to:
  /// **'Baca buku|Jalan sore|Nonton film|Tidur siang|Beres-beres'**
  String get gameWheelActivityDefaults;

  /// No description provided for @gameSpin.
  ///
  /// In id, this message translates to:
  /// **'Putar'**
  String get gameSpin;

  /// No description provided for @gameSpinAgain.
  ///
  /// In id, this message translates to:
  /// **'Putar lagi'**
  String get gameSpinAgain;

  /// No description provided for @gameReady.
  ///
  /// In id, this message translates to:
  /// **'Siap?'**
  String get gameReady;

  /// No description provided for @gameTapSpin.
  ///
  /// In id, this message translates to:
  /// **'Ketuk Putar'**
  String get gameTapSpin;

  /// No description provided for @gameSpinning.
  ///
  /// In id, this message translates to:
  /// **'Muter… muter…'**
  String get gameSpinning;

  /// No description provided for @gameWait.
  ///
  /// In id, this message translates to:
  /// **'Tunggu ya'**
  String get gameWait;

  /// No description provided for @gameNyawPicks.
  ///
  /// In id, this message translates to:
  /// **'Nyaw pilih'**
  String get gameNyawPicks;

  /// No description provided for @gameRecordExpense.
  ///
  /// In id, this message translates to:
  /// **'Catat pengeluaran'**
  String get gameRecordExpense;

  /// No description provided for @gameWheelItems.
  ///
  /// In id, this message translates to:
  /// **'Isi roda'**
  String get gameWheelItems;

  /// No description provided for @gameWheelCount.
  ///
  /// In id, this message translates to:
  /// **'{count} dari maks {max}'**
  String gameWheelCount(int count, int max);

  /// No description provided for @gameWheelAddHint.
  ///
  /// In id, this message translates to:
  /// **'Tambah pilihan, mis. Bakso'**
  String get gameWheelAddHint;

  /// No description provided for @gameRemoveOption.
  ///
  /// In id, this message translates to:
  /// **'Hapus {name}'**
  String gameRemoveOption(String name);

  /// No description provided for @gameWheelColors.
  ///
  /// In id, this message translates to:
  /// **'Warna roda'**
  String get gameWheelColors;

  /// No description provided for @gameWheelPaletteRainbow.
  ///
  /// In id, this message translates to:
  /// **'Pelangi'**
  String get gameWheelPaletteRainbow;

  /// No description provided for @gameWheelPaletteAccent.
  ///
  /// In id, this message translates to:
  /// **'Aksen'**
  String get gameWheelPaletteAccent;

  /// No description provided for @gameWheelPalettePastel.
  ///
  /// In id, this message translates to:
  /// **'Pastel'**
  String get gameWheelPalettePastel;

  /// No description provided for @gameWheelPaletteSunset.
  ///
  /// In id, this message translates to:
  /// **'Senja'**
  String get gameWheelPaletteSunset;

  /// No description provided for @gameWheelPaletteOcean.
  ///
  /// In id, this message translates to:
  /// **'Laut'**
  String get gameWheelPaletteOcean;

  /// No description provided for @gameWheelPaletteForest.
  ///
  /// In id, this message translates to:
  /// **'Hutan'**
  String get gameWheelPaletteForest;

  /// No description provided for @gameWheelPaletteCustom.
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get gameWheelPaletteCustom;

  /// No description provided for @gameWheelCustomHint.
  ///
  /// In id, this message translates to:
  /// **'Ketuk nomor irisan, lalu pilih warnanya. Warna berulang tiap 6 irisan.'**
  String get gameWheelCustomHint;

  /// No description provided for @gameWheelSlot.
  ///
  /// In id, this message translates to:
  /// **'Warna irisan {n}'**
  String gameWheelSlot(int n);

  /// No description provided for @gameWheelUseColor.
  ///
  /// In id, this message translates to:
  /// **'Pakai warna {hex}'**
  String gameWheelUseColor(String hex);

  /// No description provided for @gameWheelOtherColor.
  ///
  /// In id, this message translates to:
  /// **'Warna lain'**
  String get gameWheelOtherColor;

  /// No description provided for @gameWheelResetColors.
  ///
  /// In id, this message translates to:
  /// **'Atur ulang'**
  String get gameWheelResetColors;

  /// No description provided for @gameWheelColorsNote.
  ///
  /// In id, this message translates to:
  /// **'Berlaku untuk semua roda. Di warna kustom, tulisan otomatis hitam/putih agar tetap terbaca.'**
  String get gameWheelColorsNote;

  /// No description provided for @gameYou.
  ///
  /// In id, this message translates to:
  /// **'Kamu'**
  String get gameYou;

  /// No description provided for @gameRock.
  ///
  /// In id, this message translates to:
  /// **'Batu'**
  String get gameRock;

  /// No description provided for @gameScissors.
  ///
  /// In id, this message translates to:
  /// **'Gunting'**
  String get gameScissors;

  /// No description provided for @gamePaper.
  ///
  /// In id, this message translates to:
  /// **'Kertas'**
  String get gamePaper;

  /// No description provided for @gamePickHand.
  ///
  /// In id, this message translates to:
  /// **'Pilih tanganmu'**
  String get gamePickHand;

  /// No description provided for @gameCounting.
  ///
  /// In id, this message translates to:
  /// **'Batu… gunting… kertas!'**
  String get gameCounting;

  /// No description provided for @gameWin.
  ///
  /// In id, this message translates to:
  /// **'Kamu menang!'**
  String get gameWin;

  /// No description provided for @gameLose.
  ///
  /// In id, this message translates to:
  /// **'Nyaw menang'**
  String get gameLose;

  /// No description provided for @gameTie.
  ///
  /// In id, this message translates to:
  /// **'Seri, coba lagi'**
  String get gameTie;

  /// No description provided for @gameTieLabel.
  ///
  /// In id, this message translates to:
  /// **'Seri'**
  String get gameTieLabel;

  /// No description provided for @gameScore.
  ///
  /// In id, this message translates to:
  /// **'Skor'**
  String get gameScore;

  /// No description provided for @gameResetScore.
  ///
  /// In id, this message translates to:
  /// **'Ulang'**
  String get gameResetScore;

  /// No description provided for @gameHubTitle.
  ///
  /// In id, this message translates to:
  /// **'Rehat dulu, yuk'**
  String get gameHubTitle;

  /// No description provided for @gameHubHint.
  ///
  /// In id, this message translates to:
  /// **'Lagi penat? Main sebentar bareng Nyaw, nanti lanjut lagi.'**
  String get gameHubHint;

  /// No description provided for @gameHubFootnote.
  ///
  /// In id, this message translates to:
  /// **'Skor dan rekor tersimpan di HP-mu saja, tidak ikut tersinkron.'**
  String get gameHubFootnote;

  /// No description provided for @gameRest.
  ///
  /// In id, this message translates to:
  /// **'Rehat sebentar'**
  String get gameRest;

  /// No description provided for @gameRestAll.
  ///
  /// In id, this message translates to:
  /// **'Semua permainan'**
  String get gameRestAll;

  /// No description provided for @gameShortWheel.
  ///
  /// In id, this message translates to:
  /// **'Roda'**
  String get gameShortWheel;

  /// No description provided for @gameShortRps.
  ///
  /// In id, this message translates to:
  /// **'Suit'**
  String get gameShortRps;

  /// No description provided for @gameShortMemory.
  ///
  /// In id, this message translates to:
  /// **'Kartu'**
  String get gameShortMemory;

  /// No description provided for @gameShortPrompt.
  ///
  /// In id, this message translates to:
  /// **'Kocok ide'**
  String get gameShortPrompt;

  /// No description provided for @gameWheelDesc.
  ///
  /// In id, this message translates to:
  /// **'Bingung mau makan apa? Biar roda yang pilih.'**
  String get gameWheelDesc;

  /// No description provided for @gameRpsDesc.
  ///
  /// In id, this message translates to:
  /// **'Adu hoki lawan Nyaw, skor dihitung.'**
  String get gameRpsDesc;

  /// No description provided for @gameMemory.
  ///
  /// In id, this message translates to:
  /// **'Memory kartu'**
  String get gameMemory;

  /// No description provided for @gameMemoryDesc.
  ///
  /// In id, this message translates to:
  /// **'Cocokkan pasangan pose Nyaw.'**
  String get gameMemoryDesc;

  /// No description provided for @gameMemorySub.
  ///
  /// In id, this message translates to:
  /// **'Cocokkan 6 pasang pose Nyaw.'**
  String get gameMemorySub;

  /// No description provided for @gameMemoryRecord.
  ///
  /// In id, this message translates to:
  /// **'Rekor {moves} langkah'**
  String gameMemoryRecord(int moves);

  /// No description provided for @gameMoves.
  ///
  /// In id, this message translates to:
  /// **'Langkah'**
  String get gameMoves;

  /// No description provided for @gamePairs.
  ///
  /// In id, this message translates to:
  /// **'Pasangan'**
  String get gamePairs;

  /// No description provided for @gameBest.
  ///
  /// In id, this message translates to:
  /// **'Rekor'**
  String get gameBest;

  /// No description provided for @gameMemoryDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai dalam {moves} langkah'**
  String gameMemoryDone(int moves);

  /// No description provided for @gameMemoryNewBest.
  ///
  /// In id, this message translates to:
  /// **'Rekor baru: {moves} langkah!'**
  String gameMemoryNewBest(int moves);

  /// No description provided for @gameMemoryBestLine.
  ///
  /// In id, this message translates to:
  /// **'Rekor terbaikmu {moves} langkah.'**
  String gameMemoryBestLine(int moves);

  /// No description provided for @gamePlayAgain.
  ///
  /// In id, this message translates to:
  /// **'Main lagi'**
  String get gamePlayAgain;

  /// No description provided for @gameReshuffle.
  ///
  /// In id, this message translates to:
  /// **'Acak ulang'**
  String get gameReshuffle;

  /// No description provided for @gameCardClosed.
  ///
  /// In id, this message translates to:
  /// **'Kartu tertutup {n}'**
  String gameCardClosed(int n);

  /// No description provided for @gameCardOpen.
  ///
  /// In id, this message translates to:
  /// **'Kartu terbuka'**
  String get gameCardOpen;

  /// No description provided for @gamePrompt.
  ///
  /// In id, this message translates to:
  /// **'Kocok pertanyaan'**
  String get gamePrompt;

  /// No description provided for @gamePromptDesc.
  ///
  /// In id, this message translates to:
  /// **'Bingung mau nulis apa? Ambil satu ide.'**
  String get gamePromptDesc;

  /// No description provided for @gamePromptLabel.
  ///
  /// In id, this message translates to:
  /// **'Pertanyaan untukmu'**
  String get gamePromptLabel;

  /// No description provided for @gamePromptShuffle.
  ///
  /// In id, this message translates to:
  /// **'Kocok lagi'**
  String get gamePromptShuffle;

  /// No description provided for @gamePromptWrite.
  ///
  /// In id, this message translates to:
  /// **'Tulis jawabannya'**
  String get gamePromptWrite;

  /// No description provided for @gamePromptNote.
  ///
  /// In id, this message translates to:
  /// **'Pertanyaan dipakai sebagai judul jurnal baru, yang bisa kamu ubah. Tidak ada yang tersimpan sebelum kamu menekan Simpan.'**
  String get gamePromptNote;

  /// No description provided for @gamePromptGratitude.
  ///
  /// In id, this message translates to:
  /// **'Syukur'**
  String get gamePromptGratitude;

  /// No description provided for @gamePromptReflection.
  ///
  /// In id, this message translates to:
  /// **'Refleksi'**
  String get gamePromptReflection;

  /// No description provided for @gamePromptRelax.
  ///
  /// In id, this message translates to:
  /// **'Santai'**
  String get gamePromptRelax;

  /// No description provided for @gamePromptDreams.
  ///
  /// In id, this message translates to:
  /// **'Mimpi'**
  String get gamePromptDreams;

  /// No description provided for @gamePromptGratitudeList.
  ///
  /// In id, this message translates to:
  /// **'Hal kecil apa yang bikin kamu senyum hari ini?|Siapa yang ingin kamu ucapkan terima kasih hari ini, dan kenapa?|Apa hal sederhana yang kamu syukuri minggu ini?|Makanan apa yang paling enak hari ini?|Siapa orang yang kehadirannya bikin harimu lebih ringan?|Apa yang tubuhmu bisa lakukan hari ini dan layak disyukuri?|Kejadian tak terduga apa yang ternyata menyenangkan hari ini?|Barang apa di sekitarmu yang diam-diam sangat membantu hidupmu?|Kebaikan kecil apa yang kamu terima dari orang lain baru-baru ini?|Tempat mana yang membuatmu merasa tenang, dan kenapa kamu bersyukur punya itu?|Apa satu hal dari pagi tadi yang berjalan lebih baik dari dugaanmu?|Siapa guru atau teman yang pelajarannya masih kamu bawa sampai sekarang?|Kenangan lama apa yang masih membuatmu hangat saat diingat?|Masalah apa yang dulu terasa berat, tapi sekarang sudah lewat?|Apa yang kamu punya sekarang yang dulu hanya angan-angan?|Suara, aroma, atau pemandangan apa yang paling kamu nikmati hari ini?|Kesempatan apa yang datang minggu ini dan ingin kamu hargai?|Apa kemudahan kecil yang sering kamu lupakan, seperti air bersih atau kasur empuk?|Siapa yang diam-diam mendukungmu tanpa kamu minta?|Apa yang kamu pelajari dari kesalahan terakhirmu dan layak disyukuri?|Apa bagian dari rutinitasmu yang sebenarnya kamu sukai?|Pujian atau kata baik apa yang terakhir kamu dengar?|Apa yang membuatmu merasa cukup hari ini?|Kalau harus menulis surat terima kasih untuk dirimu sendiri, apa isinya?'**
  String get gamePromptGratitudeList;

  /// No description provided for @gamePromptReflectionList.
  ///
  /// In id, this message translates to:
  /// **'Apa yang kamu pelajari hari ini?|Kalau diulang, apa yang ingin kamu lakukan beda hari ini?|Apa yang paling menguras energimu minggu ini?|Apa satu hal yang ingin kamu lepaskan?|Kapan terakhir kali kamu merasa benar-benar jadi dirimu sendiri?|Keputusan apa yang kamu tunda, dan apa yang membuatmu ragu?|Apa yang kamu hindari belakangan ini, dan kenapa?|Hal apa yang kamu lakukan hanya karena kebiasaan, bukan karena mau?|Apa yang sebenarnya kamu butuhkan sekarang, bukan sekadar inginkan?|Kata apa yang paling menggambarkan minggu ini, dan kenapa?|Kebiasaan kecil apa yang paling berpengaruh pada suasana hatimu?|Kapan kamu merasa paling bertenaga hari ini?|Percakapan apa yang masih terngiang di kepalamu?|Apa yang kamu sesali dan apa yang bisa kamu lakukan soal itu?|Batas apa yang perlu kamu tegaskan pada orang lain atau dirimu sendiri?|Apa yang membuatmu bangga bulan ini, sekecil apa pun?|Pekerjaan atau tugas apa yang terasa paling bermakna akhir-akhir ini?|Apa yang kamu cemaskan, dan seberapa besar kemungkinannya terjadi?|Kalau kamu menasihati dirimu setahun lalu, apa katamu?|Apa yang membuatmu merasa terburu-buru, dan apakah itu perlu?|Siapa yang perlu kamu hubungi atau mintai maaf?|Apa yang ingin kamu lakukan lebih sedikit mulai besok?|Pola apa yang kamu lihat saat uangmu terasa cepat habis?|Apa satu langkah kecil yang bisa kamu ambil minggu ini?'**
  String get gamePromptReflectionList;

  /// No description provided for @gamePromptRelaxList.
  ///
  /// In id, this message translates to:
  /// **'Kalau hari ini sebuah lagu, judulnya apa?|Ceritakan satu obrolan lucu hari ini.|Kalau besok libur, kamu mau ke mana?|Apa yang bikin kamu tertawa terakhir kali?|Kalau hari ini sebuah film, genre dan judulnya apa?|Camilan apa yang paling pas menemani hari ini?|Kalau kamu punya satu jam kosong tanpa gangguan, mau diapakan?|Hewan apa yang paling menggambarkan suasana hatimu sekarang?|Warna apa yang cocok untuk harimu, dan kenapa?|Kalau bisa makan siang bersama siapa pun, kamu pilih siapa?|Apa kebiasaan anehmu yang diam-diam kamu sukai?|Lagu apa yang akhir-akhir ini sering kamu putar ulang?|Kalau kamu punya kekuatan super kecil tapi berguna, apa itu?|Tempat jajan favoritmu apa, dan pesananmu biasanya apa?|Ceritakan hal paling absurd yang kamu lihat minggu ini.|Kalau Nyaw bisa menemanimu seharian, kalian akan ngapain?|Apa hal paling nyaman yang bisa kamu lakukan saat hujan?|Kalau hidupmu punya soundtrack, lagu pembukanya apa?|Apa tontonan atau bacaan yang ingin kamu selesaikan?|Kalau kamu buka kedai kecil, kamu jual apa?|Kalau hari ini bebas anggaran tapi hanya boleh beli satu hal, apa yang kamu pilih?|Apa permainan masa kecil yang paling kamu rindukan?|Kalau besok bisa tidur sampai siang, mimpi apa yang kamu harap?|Apa yang membuat akhir pekan terasa seperti akhir pekan bagimu?'**
  String get gamePromptRelaxList;

  /// No description provided for @gamePromptDreamsList.
  ///
  /// In id, this message translates to:
  /// **'Apa satu hal yang ingin kamu capai bulan ini?|Kalau uang bukan masalah, apa yang pertama kamu beli?|Kamu ingin jadi apa lima tahun lagi?|Apa kebiasaan baik yang ingin kamu mulai?|Keterampilan apa yang ingin kamu kuasai tahun ini?|Kota atau negara mana yang ingin kamu kunjungi, dan kenapa?|Seperti apa hari yang sempurna menurutmu, dari bangun sampai tidur?|Apa yang ingin kamu tabung, dan berapa lama kamu rela menunggu?|Kalau kamu bisa mengganti satu hal di hidupmu sekarang, apa itu?|Rumah seperti apa yang kamu impikan?|Proyek kecil apa yang ingin kamu mulai sebelum akhir tahun?|Siapa yang ingin kamu temui atau hubungi lagi?|Apa yang ingin kamu ajarkan pada orang lain suatu hari nanti?|Kalau gagal itu mustahil, apa yang akan kamu coba?|Pengalaman apa yang ingin kamu rasakan sekali seumur hidup?|Apa yang ingin kamu ingat tentang tahun ini?|Buku apa yang ingin kamu baca atau tulis?|Seperti apa pekerjaan idealmu dalam satu kalimat?|Apa satu ketakutan yang ingin kamu taklukkan?|Kebiasaan buruk apa yang ingin kamu ganti dengan yang lebih baik?|Apa tujuan keuanganmu yang paling dekat?|Hal apa yang ingin kamu lakukan bersama keluarga atau teman tahun ini?|Apa yang ingin kamu katakan pada dirimu lima tahun lagi?|Apa satu mimpi lama yang masih ingin kamu hidupkan?'**
  String get gamePromptDreamsList;

  /// No description provided for @updateCheckNotFound.
  ///
  /// In id, this message translates to:
  /// **'Rilis belum ditemukan di GitHub. Coba lagi nanti.'**
  String get updateCheckNotFound;

  /// No description provided for @updateCheckRateLimited.
  ///
  /// In id, this message translates to:
  /// **'Terlalu sering mengecek. Coba lagi beberapa menit lagi.'**
  String get updateCheckRateLimited;

  /// No description provided for @updateCheckServer.
  ///
  /// In id, this message translates to:
  /// **'Server GitHub sedang bermasalah. Coba lagi nanti.'**
  String get updateCheckServer;

  /// No description provided for @calPrevMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan sebelumnya'**
  String get calPrevMonth;

  /// No description provided for @calNextMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan berikutnya'**
  String get calNextMonth;

  /// No description provided for @calHint.
  ///
  /// In id, this message translates to:
  /// **'Ketuk tanggal untuk melihat transaksi hari itu.'**
  String get calHint;

  /// No description provided for @calShowAllDays.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan semua hari'**
  String get calShowAllDays;

  /// No description provided for @calOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get calOut;

  /// No description provided for @calIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get calIn;

  /// No description provided for @calDayEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada transaksi di tanggal ini.'**
  String get calDayEmpty;

  /// No description provided for @calRecord.
  ///
  /// In id, this message translates to:
  /// **'Catat'**
  String get calRecord;

  /// No description provided for @calNoData.
  ///
  /// In id, this message translates to:
  /// **'belum ada data'**
  String get calNoData;

  /// No description provided for @remSection.
  ///
  /// In id, this message translates to:
  /// **'PENGINGAT DARI CERITAMU'**
  String get remSection;

  /// No description provided for @remNone.
  ///
  /// In id, this message translates to:
  /// **'Belum ada tanggal atau jam di ceritamu. Kalau kamu menyebut rencana, Nyaw menawarkan pengingat di sini.'**
  String get remNone;

  /// No description provided for @remDetected.
  ///
  /// In id, this message translates to:
  /// **'Terdeteksi acara'**
  String get remDetected;

  /// No description provided for @remWillRemind.
  ///
  /// In id, this message translates to:
  /// **'Akan diingatkan'**
  String get remWillRemind;

  /// No description provided for @remAllDay.
  ///
  /// In id, this message translates to:
  /// **'Sepanjang hari'**
  String get remAllDay;

  /// No description provided for @remTomorrow.
  ///
  /// In id, this message translates to:
  /// **'Besok'**
  String get remTomorrow;

  /// No description provided for @remDaysLeft.
  ///
  /// In id, this message translates to:
  /// **'{days} hari lagi'**
  String remDaysLeft(int days);

  /// No description provided for @remAmbiguous.
  ///
  /// In id, this message translates to:
  /// **'Jamnya belum jelas. Maksudmu yang mana?'**
  String get remAmbiguous;

  /// No description provided for @remMismatch.
  ///
  /// In id, this message translates to:
  /// **'{date} jatuh hari {actual}, bukan {said}. Nyaw memakai tanggalnya.'**
  String remMismatch(String date, String actual, String said);

  /// No description provided for @remAccept.
  ///
  /// In id, this message translates to:
  /// **'Ingatkan aku'**
  String get remAccept;

  /// No description provided for @remEdit.
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get remEdit;

  /// No description provided for @remDismiss.
  ///
  /// In id, this message translates to:
  /// **'Abaikan'**
  String get remDismiss;

  /// No description provided for @remActive.
  ///
  /// In id, this message translates to:
  /// **'Pengingat aktif · {lead}'**
  String remActive(String lead);

  /// No description provided for @remLeadAt.
  ///
  /// In id, this message translates to:
  /// **'saat acara'**
  String get remLeadAt;

  /// No description provided for @remLeadHour.
  ///
  /// In id, this message translates to:
  /// **'1 jam sebelum'**
  String get remLeadHour;

  /// No description provided for @remLeadDay.
  ///
  /// In id, this message translates to:
  /// **'1 hari sebelum'**
  String get remLeadDay;

  /// No description provided for @remLeadMorning.
  ///
  /// In id, this message translates to:
  /// **'pagi hari-H, 07.00'**
  String get remLeadMorning;

  /// No description provided for @remLeadMorningShort.
  ///
  /// In id, this message translates to:
  /// **'pagi hari-H'**
  String get remLeadMorningShort;

  /// No description provided for @remPrivacy.
  ///
  /// In id, this message translates to:
  /// **'Dikenali di HP-mu sendiri, tanpa internet.'**
  String get remPrivacy;

  /// No description provided for @remEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah pengingat'**
  String get remEditTitle;

  /// No description provided for @remEditSub.
  ///
  /// In id, this message translates to:
  /// **'Perbaiki kalau tebakan Nyaw kurang pas.'**
  String get remEditSub;

  /// No description provided for @remFieldTitle.
  ///
  /// In id, this message translates to:
  /// **'Judul acara'**
  String get remFieldTitle;

  /// No description provided for @remFieldDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get remFieldDate;

  /// No description provided for @remFieldTime.
  ///
  /// In id, this message translates to:
  /// **'Jam'**
  String get remFieldTime;

  /// No description provided for @remFieldLead.
  ///
  /// In id, this message translates to:
  /// **'Ingatkan'**
  String get remFieldLead;

  /// No description provided for @remSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan pengingat'**
  String get remSave;

  /// No description provided for @remDefaultTitle.
  ///
  /// In id, this message translates to:
  /// **'Acara'**
  String get remDefaultTitle;

  /// No description provided for @remPermTitle.
  ///
  /// In id, this message translates to:
  /// **'Izinkan notifikasi?'**
  String get remPermTitle;

  /// No description provided for @remPermBody.
  ///
  /// In id, this message translates to:
  /// **'Supaya Nyawtat bisa mengingatkanmu tepat waktu. Hanya ditanya sekali.'**
  String get remPermBody;

  /// No description provided for @remPermHint.
  ///
  /// In id, this message translates to:
  /// **'Tanpa izin, acara tetap tersimpan dan tampil di Hari Ini, tapi tidak ada notifikasi.'**
  String get remPermHint;

  /// No description provided for @remPermLater.
  ///
  /// In id, this message translates to:
  /// **'Nanti saja'**
  String get remPermLater;

  /// No description provided for @remPermAllow.
  ///
  /// In id, this message translates to:
  /// **'Izinkan'**
  String get remPermAllow;

  /// No description provided for @remUpcoming.
  ///
  /// In id, this message translates to:
  /// **'Acara mendatang'**
  String get remUpcoming;

  /// No description provided for @remDenied.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi belum diizinkan, jadi acara hanya tampil di daftar ini.'**
  String get remDenied;

  /// No description provided for @remAllowButton.
  ///
  /// In id, this message translates to:
  /// **'Izinkan notifikasi'**
  String get remAllowButton;

  /// No description provided for @remLeadLine.
  ///
  /// In id, this message translates to:
  /// **'Diingatkan {lead}'**
  String remLeadLine(String lead);

  /// No description provided for @remFrom.
  ///
  /// In id, this message translates to:
  /// **'Dari catatan {date}'**
  String remFrom(String date);

  /// No description provided for @remDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus pengingat'**
  String get remDelete;

  /// No description provided for @remClose.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get remClose;

  /// No description provided for @remNotifHour.
  ///
  /// In id, this message translates to:
  /// **'1 jam lagi'**
  String get remNotifHour;

  /// No description provided for @remNotifNow.
  ///
  /// In id, this message translates to:
  /// **'Sekarang'**
  String get remNotifNow;

  /// No description provided for @remCreated.
  ///
  /// In id, this message translates to:
  /// **'{count} pengingat dibuat'**
  String remCreated(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
