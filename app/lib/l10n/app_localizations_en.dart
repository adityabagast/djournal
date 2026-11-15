// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Nyawtat';

  @override
  String get splashTagline => 'journal & money notes';

  @override
  String get navToday => 'Today';

  @override
  String get navJournal => 'Journal';

  @override
  String get navMoney => 'Money';

  @override
  String get navReport => 'Report';

  @override
  String get add => 'Add';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get comingSoon => 'Coming in the next phase.';

  @override
  String get todaySpent => 'Spent today';

  @override
  String monthSpent(String amount) {
    return 'This month $amount';
  }

  @override
  String get record => 'Add';

  @override
  String get todayTimeline => 'Today\'s timeline';

  @override
  String get write => 'Write';

  @override
  String get timelineEmpty =>
      'Nothing recorded today yet. Write a journal entry or add a transaction.';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get net => 'Net';

  @override
  String get wallets => 'Wallets';

  @override
  String get addWallet => 'Add wallet';

  @override
  String get filterAll => 'All';

  @override
  String get noTransactions => 'No transactions yet.';

  @override
  String get addTxTitle => 'Add Transaction';

  @override
  String get editTxTitle => 'Edit Transaction';

  @override
  String get amount => 'Amount';

  @override
  String get amountRequired => 'Please enter an amount.';

  @override
  String get category => 'Category';

  @override
  String get wallet => 'Wallet';

  @override
  String get time => 'Time';

  @override
  String get note => 'Note';

  @override
  String get noteHint => 'e.g. lunch at the canteen';

  @override
  String get saveTx => 'Save transaction';

  @override
  String get transferFrom => 'From';

  @override
  String get transferTo => 'To';

  @override
  String walletBalance(String amount) {
    return 'Balance $amount';
  }

  @override
  String get swapWallets => 'Swap source and destination wallets';

  @override
  String transferOverdraw(String wallet) {
    return '$wallet balance is lower than the amount. You can still save.';
  }

  @override
  String get transferNeedsTwoWallets => 'Transfers need at least 2 wallets.';

  @override
  String get saveTransfer => 'Save transfer';

  @override
  String get transferNoteHint => 'e.g. ATM cash withdrawal';

  @override
  String get toastTransferSaved => 'Transfer saved';

  @override
  String get deleteTxConfirm => 'Delete this transaction?';

  @override
  String get quickAdd => 'Quick add';

  @override
  String get quickAddTx => 'Add transaction';

  @override
  String get quickAddTxSub => 'Expense, income, or transfer';

  @override
  String get quickAddJournal => 'Write journal';

  @override
  String get quickAddJournalSub => 'New story, optional time and mood';

  @override
  String get reportByCategory => 'Spending by category';

  @override
  String get reportEmpty => 'No spending this month yet.';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystemHint =>
      'Follows your phone\'s dark mode setting. Home screen widgets follow too.';

  @override
  String get themeLightHint =>
      'Always light, whatever your phone\'s setting. Home screen widgets follow too.';

  @override
  String get themeDarkHint =>
      'Always dark, whatever your phone\'s setting. Home screen widgets follow too.';

  @override
  String get accentTitle => 'Accent color';

  @override
  String get accentHint =>
      'Used for buttons, active icons, and the Total balance card, in both light and dark mode.';

  @override
  String get accentSage => 'Sage green';

  @override
  String get accentOcean => 'Ocean blue';

  @override
  String get accentViolet => 'Violet';

  @override
  String get accentRose => 'Rose';

  @override
  String get accentPink => 'Pink';

  @override
  String get accentAmber => 'Amber';

  @override
  String get accentTeal => 'Teal';

  @override
  String get accentCustom => 'Custom';

  @override
  String get accentCustomA11y => 'Custom color, pick your own';

  @override
  String accentCustomHint(String hex) {
    return 'Custom $hex · tap Custom again to change it. Income and expense colors stay the same.';
  }

  @override
  String get accentCustomTitle => 'Custom color';

  @override
  String get accentCustomSub => 'Drag to pick, or type a hex code.';

  @override
  String get accentHue => 'Hue';

  @override
  String get accentSaturation => 'Saturation';

  @override
  String get accentLightness => 'Lightness';

  @override
  String get accentHexLabel => 'Hex code';

  @override
  String get accentHexError => 'Format: #RRGGBB, e.g. #1F5F4E';

  @override
  String get accentRecent => 'Recently used';

  @override
  String get accentPreviewChip => 'Selected';

  @override
  String get accentNoteGrey =>
      'This color is nearly gray, so the accent stands out less than other colors.';

  @override
  String get accentNoteLight =>
      'Fairly light color. In light mode, buttons are made a bit darker so their text stays readable.';

  @override
  String get accentNoteDark =>
      'Very dark color. In light mode, buttons are made a bit lighter so they still look colored.';

  @override
  String get accentApply => 'Use color';

  @override
  String get currency => 'Currency';

  @override
  String get currencyValue => 'Rupiah (IDR)';

  @override
  String versionLabel(String version) {
    return 'Nyawtat · version $version';
  }

  @override
  String get walletName => 'Wallet name';

  @override
  String get walletNameHint => 'e.g. BCA, GoPay';

  @override
  String get walletType => 'Type';

  @override
  String get walletTypeCash => 'Cash';

  @override
  String get walletTypeBank => 'Bank';

  @override
  String get walletTypeEwallet => 'E-wallet';

  @override
  String get walletTypeOther => 'Other';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get walletNameRequired => 'Please enter a wallet name.';

  @override
  String get editWallet => 'Edit wallet';

  @override
  String get deleteWallet => 'Delete wallet';

  @override
  String deleteWalletConfirm(String name) {
    return 'Delete wallet $name?';
  }

  @override
  String deleteWalletTxWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions in this wallet will also be deleted.',
      one: '1 transaction in this wallet will also be deleted.',
    );
    return '$_temp0';
  }

  @override
  String get lastWalletCantDelete => 'You can\'t delete your last wallet.';

  @override
  String get catFood => 'Food';

  @override
  String get catTransport => 'Transport';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catBills => 'Bills';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catOther => 'Other';

  @override
  String get catSalary => 'Salary';

  @override
  String get catBonus => 'Bonus';

  @override
  String get catOtherIncome => 'Other';

  @override
  String get moodAwful => 'Awful';

  @override
  String get moodBad => 'Bad';

  @override
  String get moodOkay => 'Okay';

  @override
  String get moodGood => 'Good';

  @override
  String get moodGreat => 'Great';

  @override
  String get journalEmpty =>
      'No journal entries yet. Start writing your first story.';

  @override
  String get showAllEntries => 'Show all';

  @override
  String get journalDayEmptyTitle => 'No entries';

  @override
  String get journalDayEmptyBody => 'Nothing written on this day.';

  @override
  String get writeForThisDay => 'Write for this day';

  @override
  String get prevWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String dayMoodSummary(String mood) {
    return 'Mood $mood';
  }

  @override
  String get noSpending => 'no spending';

  @override
  String get untitled => 'Untitled';

  @override
  String get newEntryTitle => 'New Entry';

  @override
  String get editEntryTitle => 'Edit Entry';

  @override
  String get entryTime => 'Time of event';

  @override
  String get optional => '(optional)';

  @override
  String get now => 'Now';

  @override
  String get clearTime => 'Clear time';

  @override
  String get pickTime => 'Pick time';

  @override
  String get mood => 'Mood';

  @override
  String get entryTitle => 'Title';

  @override
  String get entryTitleHint => 'One sentence about what happened';

  @override
  String get story => 'Story';

  @override
  String get storyHint => 'What happened? How did you feel?';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHint => 'Separate with commas, e.g. friends, work';

  @override
  String get dayTransactions => 'Transactions on this day';

  @override
  String get linkedByDate => 'Linked automatically by date.';

  @override
  String get entryEmptyError => 'Please write a title or a story.';

  @override
  String get deleteEntryConfirm => 'Delete this entry?';

  @override
  String get moodSpending => 'Mood & spending';

  @override
  String get avgGoodMood => 'Average on good-mood days';

  @override
  String get avgLowMood => 'Average on low-mood days';

  @override
  String get noData => 'No data yet';

  @override
  String get insightNeedMore =>
      'Log your mood in a few more journal entries to see the pattern.';

  @override
  String get insightSpendWhenLow =>
      'You tend to spend more on rough days. Try postponing impulse buys on hard days.';

  @override
  String get insightSpendWhenGood => 'You spend more on good days.';

  @override
  String get budget => 'Budget';

  @override
  String get budgetPerCategory => 'Budget by category';

  @override
  String get manage => 'Manage';

  @override
  String budgetUsage(String month, int pct, String left) {
    return '$month budget $pct% used · $left left';
  }

  @override
  String budgetUsedPct(int pct) {
    return '$pct% used';
  }

  @override
  String get widgetBalance => 'Balance';

  @override
  String get widgetTodayOut => 'Spent today';

  @override
  String get widgetTodaySuffix => 'spent today';

  @override
  String get widgetJournalTitle => 'Today\'s journal';

  @override
  String widgetJournalSummary(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0 · last $time';
  }

  @override
  String get widgetJournalEmptyTitle => 'How was your day?';

  @override
  String get widgetJournalEmptySub => 'No story yet today';

  @override
  String widgetBudgetOver(String month, String amount) {
    return '$month budget over by $amount';
  }

  @override
  String overBudget(String amount) {
    return 'Over budget by $amount';
  }

  @override
  String get noBudget => 'No budget';

  @override
  String get budgetLimit => 'Monthly limit';

  @override
  String get budgetHint => 'Leave empty for no budget';

  @override
  String budgetAppliesFrom(String month) {
    return 'Applies from $month onward.';
  }

  @override
  String get budgetSubtitle => 'Set monthly spending limits per category';

  @override
  String get budgetTotal => 'Total budget';

  @override
  String get data => 'Data';

  @override
  String get account => 'Account';

  @override
  String get signInPrompt =>
      'Sign in to keep your data on the server and use it on several devices.';

  @override
  String get signIn => 'Sign in';

  @override
  String get register => 'Create account';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'At least 8 characters';

  @override
  String get errConfirmEmail =>
      'Check your email and click the confirmation link, then sign in.';

  @override
  String get backendNotConfigured => 'Sync is not configured in this build.';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get exportBackupSub => 'All data in one JSON file';

  @override
  String get exportExcel => 'Export to Excel';

  @override
  String get exportExcelSub =>
      'Transactions, journal, wallets and budgets in one .xlsx file';

  @override
  String get sheetTransactions => 'Transactions';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get spent => 'Spent';

  @override
  String get remaining => 'Remaining';

  @override
  String get importBackup => 'Import backup';

  @override
  String get importBackupSub => 'Restore data from a backup file';

  @override
  String importConfirm(String file) {
    return 'Import $file?';
  }

  @override
  String get importConfirmBody =>
      'The file is merged with your existing data. Nothing is deleted; where the same item exists, the newer version wins.';

  @override
  String get importAction => 'Import';

  @override
  String importDone(int imported, int skipped) {
    return '$imported items imported, $skipped already present';
  }

  @override
  String get importInvalid => 'This file is not a valid Nyawtat backup.';

  @override
  String get exportFailed => 'Export failed.';

  @override
  String get security => 'Security';

  @override
  String get lockWithPin => 'Lock with PIN';

  @override
  String get lockWithPinSub => 'Ask for a PIN when the app opens';

  @override
  String get unlockWithBiometric => 'Unlock with biometrics';

  @override
  String get unlockWithBiometricSub => 'Fingerprint or face';

  @override
  String get biometricUnavailable => 'Not available on this device';

  @override
  String get lockNow => 'Lock app now';

  @override
  String get hideAmounts => 'Hide amounts';

  @override
  String get hideAmountsSub =>
      'Mask balances and monetary amounts across the app';

  @override
  String get enterPin => 'Enter your PIN to unlock';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String tooManyAttempts(int seconds) {
    return 'Too many attempts. Try again in $seconds seconds.';
  }

  @override
  String get useBiometric => 'Use biometrics';

  @override
  String get biometricReason => 'Unlock Nyawtat';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get forgotPinTitle => 'Reset PIN?';

  @override
  String get forgotPinBody =>
      'You will be signed out and the data on this device removed. Synced data stays safe on the server and returns when you sign in again.';

  @override
  String get forgotPinBodyLocal =>
      'All data on this device will be permanently deleted because you are not signed in (there is no copy on the server).';

  @override
  String get resetPin => 'Reset';

  @override
  String get createPin => 'Create PIN';

  @override
  String get createPinHint => 'Pick 4 digits you can remember';

  @override
  String get confirmPin => 'Repeat PIN';

  @override
  String get confirmPinHint => 'Type the same PIN again';

  @override
  String get pinMismatch => 'PINs do not match. Start again.';

  @override
  String get currentPin => 'Current PIN';

  @override
  String get currentPinHint => 'Enter your PIN to continue';

  @override
  String get deleteDigit => 'Delete digit';

  @override
  String get transfer => 'Transfer';

  @override
  String get csvDate => 'Date';

  @override
  String get csvTime => 'Time';

  @override
  String get csvType => 'Type';

  @override
  String get csvToWallet => 'To wallet';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get noAccount => 'No account yet? Create one';

  @override
  String get syncNow => 'Sync';

  @override
  String get syncing => 'Syncing…';

  @override
  String lastSynced(String time) {
    return 'Last synced: $time';
  }

  @override
  String get neverSynced => 'Never synced';

  @override
  String get signOutConfirm => 'Sign out?';

  @override
  String get signOutBody =>
      'Data on this device will be removed. Synced data stays safe on the server and comes back when you sign in again.';

  @override
  String get signOutUnsynced =>
      'Some changes haven\'t synced yet and will be lost if you sign out now.';

  @override
  String get errNetwork =>
      'Can\'t reach the server. Check the server address and your connection.';

  @override
  String get errInvalidCredentials => 'Wrong email or password.';

  @override
  String get errEmailTaken =>
      'This email is already registered. Try signing in.';

  @override
  String get errInvalidEmail => 'Invalid email format.';

  @override
  String get errPasswordTooShort => 'Password must be at least 8 characters.';

  @override
  String get errSessionExpired => 'Session expired. Please sign in again.';

  @override
  String get errServer =>
      'Something went wrong on the server. Try again later.';

  @override
  String get mascotTodayEmptyTitle => 'Hi! Today is still empty';

  @override
  String get mascotJournalEmptyTitle => 'No entries yet';

  @override
  String get mascotJournalEmptyBody =>
      'Write a little about your day: mood, stories, or spending.';

  @override
  String get mascotWriteEntry => 'Write an entry';

  @override
  String get mascotTxEmptyTitle => 'No transactions yet';

  @override
  String get mascotTxEmptyBody => 'Record your first income or expense.';

  @override
  String get mascotRecordTx => 'Record a transaction';

  @override
  String get mascotFilterEmptyTitle => 'Nothing found';

  @override
  String get mascotFilterEmptyBody => 'No transactions match this filter yet.';

  @override
  String get mascotReportEmptyTitle => 'No data this month yet';

  @override
  String get mascotReportEmptyBody =>
      'The report appears once you record some spending.';

  @override
  String get mascotNoBudgetTitle => 'No budget yet';

  @override
  String get mascotNoBudgetBody =>
      'Set a budget to keep your spending in check.';

  @override
  String get mascotBudgetOkTitle => 'All budgets are on track';

  @override
  String get mascotBudgetOkBody => 'Keep it up until the end of the month!';

  @override
  String mascotBudgetOverTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories over budget',
      one: '1 category over budget',
    );
    return '$_temp0';
  }

  @override
  String mascotBudgetOverBody(String names) {
    return '$names. Maybe ease off a little.';
  }

  @override
  String get toastEntrySaved => 'Entry saved';

  @override
  String get toastEntryUpdated => 'Entry updated';

  @override
  String get toastTxSaved => 'Transaction saved';

  @override
  String toastBudgetOver(String category) {
    return '$category budget exceeded';
  }

  @override
  String get toastSynced => 'Sync complete';

  @override
  String get importMm => 'Import from Money Manager';

  @override
  String get importMmSub =>
      'Backup .mmbak or .xlsx export from Money Manager (Realbyte)';

  @override
  String get importMmReading => 'Reading file…';

  @override
  String importMmNew(int count) {
    return '$count new transactions';
  }

  @override
  String importMmBreakdown(int expense, int income, int transfer) {
    return '$expense expenses · $income income · $transfer transfers';
  }

  @override
  String importMmPeriod(String from, String to) {
    return 'Period: $from – $to';
  }

  @override
  String importMmAlready(int count) {
    return '$count transactions were imported before and are skipped.';
  }

  @override
  String importMmSkipped(int count) {
    return '$count transfers to the same wallet are skipped.';
  }

  @override
  String importMmAdjust(int count) {
    return '$count \"Modified balance\" rows are added to the wallets\' opening balance.';
  }

  @override
  String get importMmWallets => 'Wallets';

  @override
  String get importMmNewWallet => 'new wallet';

  @override
  String importMmNewCategories(int count) {
    return 'New categories ($count)';
  }

  @override
  String get importMmOverlap =>
      'Transactions you recorded yourself in Nyawtat are not matched. After importing, check overlapping dates for duplicates.';

  @override
  String get importMmNothing => 'Nothing new to import in this file.';

  @override
  String importMmDone(int count) {
    return '$count transactions imported';
  }

  @override
  String get importMmInvalid =>
      'This file is not recognized as Money Manager data.';

  @override
  String get archiveWallet => 'Archive wallet';

  @override
  String get unarchiveWallet => 'Unarchive';

  @override
  String get archiveWalletHint =>
      'Archived wallets are hidden from the list and total balance, but their transactions stay in history and reports.';

  @override
  String archivedWalletsCard(int count) {
    return 'Archive ($count)';
  }

  @override
  String get archivedWalletsTitle => 'Archived wallets';

  @override
  String get walletArchivedBadge => 'Archived';

  @override
  String get toastWalletArchived => 'Wallet archived';

  @override
  String get toastWalletUnarchived => 'Wallet unarchived';

  @override
  String get importMmArchived => 'archived';

  @override
  String importMmMoved(int count) {
    return '$count previously imported transactions are moved to the right wallet.';
  }

  @override
  String get currentBalanceHint =>
      'If you change the balance, the difference is recorded as an Other transaction.';

  @override
  String get balanceAdjustmentNote => 'Balance adjustment';

  @override
  String get manageWallets => 'Manage wallets';

  @override
  String get manageAction => 'Manage';

  @override
  String get activeWallets => 'Active';

  @override
  String walletsTotal(int count) {
    return 'Total balance of $count active wallets';
  }

  @override
  String walletTxCount(int count) {
    return '$count transactions';
  }

  @override
  String archivedWalletLine(int count, String amount) {
    return '$count transactions · balance $amount';
  }

  @override
  String get unarchiveShort => 'Restore';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get categoriesSub => 'Reorder, hide, or merge categories';

  @override
  String get categoryReorderHint =>
      'Hold the handle on the left and drag to reorder. The same order is used when recording a transaction.';

  @override
  String get categorySystemBadge => 'built-in';

  @override
  String categoryBudgetMeta(String amount) {
    return 'budget $amount';
  }

  @override
  String hiddenCategoriesTitle(int count) {
    return 'Hidden ($count)';
  }

  @override
  String get hiddenCategoriesHint =>
      'Not shown when recording a transaction. Older transactions keep this category.';

  @override
  String get noHiddenCategories => 'No hidden categories yet.';

  @override
  String get showCategory => 'Show';

  @override
  String get newExpenseCategory => 'New expense category';

  @override
  String get newIncomeCategory => 'New income category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryNameHint => 'e.g. Mobile data, Bank fees';

  @override
  String get categoryNameRequired => 'Please enter a category name.';

  @override
  String get systemCategoryNameNote =>
      'Built-in category names follow the app language.';

  @override
  String get categoryColor => 'Color';

  @override
  String get hideFromForm => 'Hide from the form';

  @override
  String get showInForm => 'Show in the form again';

  @override
  String get mergeCategory => 'Merge into another category…';

  @override
  String mergeCategoryTitle(String name) {
    return 'Merge $name into…';
  }

  @override
  String mergeCategoryHint(int count, String name) {
    return '$count transactions will be moved, then $name is deleted.';
  }

  @override
  String get mergeConfirmTitle => 'Merge categories?';

  @override
  String mergeConfirmBody(int count, String from, String to) {
    return '$count transactions in $from will be moved to $to, then $from is deleted. This can\'t be undone.';
  }

  @override
  String get mergeAction => 'Merge';

  @override
  String get deleteCategory => 'Delete category';

  @override
  String get deleteSystemCategoryHint =>
      'Built-in categories can\'t be deleted, but they can be hidden.';

  @override
  String deleteUsedCategoryHint(int count) {
    return 'Still used by $count transactions. Merge it into another category first.';
  }

  @override
  String get toastCategorySaved => 'Category saved';

  @override
  String toastCategoryHidden(String name) {
    return '$name hidden';
  }

  @override
  String toastCategoryShown(String name) {
    return '$name shown again';
  }

  @override
  String toastCategoryMerged(String from, String to) {
    return '$from merged into $to';
  }

  @override
  String get toastCategoryDeleted => 'Category deleted';

  @override
  String get categoryIcon => 'Icon';

  @override
  String get categoryIconNone => 'No icon (first letter)';

  @override
  String get iconFood => 'Food';

  @override
  String get iconCoffee => 'Coffee';

  @override
  String get iconCar => 'Car';

  @override
  String get iconMotorbike => 'Motorbike';

  @override
  String get iconShopping => 'Shopping';

  @override
  String get iconBills => 'Bills';

  @override
  String get iconData => 'Mobile data';

  @override
  String get iconEntertainment => 'Entertainment';

  @override
  String get iconHealth => 'Health';

  @override
  String get iconEducation => 'Education';

  @override
  String get iconGift => 'Gift';

  @override
  String get iconClothes => 'Clothes';

  @override
  String get iconHome => 'Home';

  @override
  String get iconFriends => 'Friends';

  @override
  String get iconCharity => 'Charity';

  @override
  String get iconSalary => 'Salary';

  @override
  String get iconSavings => 'Savings';

  @override
  String get iconInvestment => 'Investment';

  @override
  String get iconTravel => 'Travel';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search journal, notes, categories, amounts…';

  @override
  String get clearText => 'Clear text';

  @override
  String get searchScopeAll => 'All';

  @override
  String get searchScopeTx => 'Transactions';

  @override
  String get periodAll => 'All time';

  @override
  String get periodThisMonth => 'This month';

  @override
  String get periodThreeMonths => '3 months';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearRecentSearches => 'Clear';

  @override
  String get trySearching => 'Try searching';

  @override
  String searchCountEntries(int count) {
    return '$count journal entries';
  }

  @override
  String searchSumOut(String amount) {
    return 'spent $amount';
  }

  @override
  String searchSumIn(String amount) {
    return 'received $amount';
  }

  @override
  String get searchNotFound => 'Nothing found';

  @override
  String searchNotFoundBody(String query) {
    return 'No journal entries or transactions match \"$query\".';
  }

  @override
  String searchNotFoundPeriodBody(String query) {
    return 'No journal entries or transactions match \"$query\" in this period.';
  }

  @override
  String get voiceNote => 'Voice note';

  @override
  String get recordVoice => 'Record voice';

  @override
  String get recordAgain => 'Record again';

  @override
  String get recordingVoice => 'Recording voice...';

  @override
  String get transcription => 'Speech transcription';

  @override
  String get copyToStory => 'Copy to story';

  @override
  String get copiedToStory => 'Transcription copied to story';

  @override
  String get deleteVoiceConfirm => 'Delete this voice recording?';

  @override
  String get quickAddVoice => 'Voice note';

  @override
  String get quickAddVoiceSub => 'Record story & auto-transcribe';

  @override
  String get micPermissionRequired =>
      'Microphone permission is required to record voice.';

  @override
  String get chartDistribution => 'Categories';

  @override
  String get chartWeekly => 'Weekly';

  @override
  String get chartExpenseAnalysis => 'Expense Analysis';

  @override
  String get chartExpenseByCategory => 'Category Distribution';

  @override
  String get chartWeeklyTrend => 'Weekly Trend';

  @override
  String chartAllCategories(int count) {
    return 'All categories ($count)';
  }

  @override
  String get chartShowLess => 'Show less';

  @override
  String get chartAvgWeekly => 'Avg/week';

  @override
  String chartHighestWeek(int week) {
    return 'Highest: W$week';
  }

  @override
  String get prevMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get thisMonth => 'This month';

  @override
  String get totalExpense => 'Total Expense';

  @override
  String categoryCount(int count) {
    return '$count categories';
  }

  @override
  String get googleDriveBackup => 'Google Drive Backup';

  @override
  String get googleDriveBackupSub => 'Automatic & self-hosted cloud sync';

  @override
  String get googleDriveConnected => 'Connected';

  @override
  String get googleDriveNotConnected => 'Not connected';

  @override
  String get googleDriveConnect => 'Connect Google Account';

  @override
  String get googleDriveDisconnect => 'Disconnect Account';

  @override
  String googleDriveLastBackup(String time) {
    return 'Last backup: $time';
  }

  @override
  String get googleDriveNever => 'Never backed up';

  @override
  String get googleDriveFormatInfo => 'Format: Excel (.xlsx) / Sheets';

  @override
  String get googleDriveFormatDesc =>
      'View and edit directly in Google Sheets with 4 tabs: Transactions, Journal, Wallets, and Budget.';

  @override
  String get googleDriveSheetsPreview => 'Sheets Preview';

  @override
  String get googleSignIn => 'Sign in with Google';

  @override
  String get googleSignInPrompt =>
      'Sign in with Google to automatically backup to Google Drive.';

  @override
  String get guestMode => 'Guest Mode (Offline)';

  @override
  String get guestModePrompt =>
      'Sign in with Google or server Email to backup your data.';

  @override
  String get nyawtatServerConnected => 'Nyawtat Server Connected';

  @override
  String get googleDriveConnectedBadge => 'Google Drive Connected';

  @override
  String get signInAccount => 'Sign In';

  @override
  String get backupRange => 'Backup Data Range';

  @override
  String get rangeAll => 'All Time';

  @override
  String get rangeThisYear => 'This Year';

  @override
  String get rangeThisMonth => 'This Month';

  @override
  String get rangeCustom => 'Custom Range';

  @override
  String get rangeCustomFrom => 'From';

  @override
  String get rangeCustomTo => 'To';

  @override
  String get backupNow => 'Backup to Drive';

  @override
  String get backupNowSuccess => 'Successfully backed up to Google Drive!';

  @override
  String get backupNowLoading => 'Uploading to Drive...';

  @override
  String get openInSheets => 'Open in Sheets';

  @override
  String get restoreFromDrive => 'Restore from Drive';

  @override
  String get restoreFromDriveConfirm =>
      'Restore data from Google Drive backup? Local data will be synced.';

  @override
  String get restoreFromDriveSuccess =>
      'Data successfully restored from Google Drive!';

  @override
  String get localDataTitle => 'Local Storage';

  @override
  String get localBackup => 'Backup Data (Export)';

  @override
  String get localBackupSub =>
      'Save Excel (.xlsx) or Backup (.json) file to device';

  @override
  String get localRestore => 'Restore / Import Data';

  @override
  String get localRestoreSub => 'Auto-detect Nyawtat or Money Manager file';

  @override
  String get formatExcel => 'Excel Report (.xlsx)';

  @override
  String get formatExcelDesc =>
      'Can be opened, analyzed, and printed in Google Sheets / Excel.';

  @override
  String get formatJson => 'Nyawtat Backup File (.json)';

  @override
  String get formatJsonDesc =>
      'Full backup with relational data for restoring to another device.';

  @override
  String get exportAction => 'Export & Share File';

  @override
  String get selectBackupFile => 'Select Backup File';

  @override
  String get selectBackupFileHint =>
      'Supports .json (Nyawtat) or .mmbak / .sqlite / .xlsx (Money Manager)';

  @override
  String get autoBackupWifi => 'Auto Backup';

  @override
  String get autoBackupWifiSub => 'When connected to Wi-Fi';

  @override
  String get unsupportedFileFormat =>
      'Unsupported file format. Please select a .json backup or a Money Manager file.';

  @override
  String get addSubcategory => 'Subcategory';

  @override
  String allOfCategory(String name) {
    return 'All $name';
  }

  @override
  String subcategoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subcategories',
      one: '1 subcategory',
    );
    return '$_temp0';
  }

  @override
  String newSubcategory(String parent) {
    return 'New subcategory in $parent';
  }

  @override
  String get editSubcategory => 'Edit subcategory';

  @override
  String subcategoryColorNote(String parent) {
    return 'Uses the color of $parent.';
  }

  @override
  String get greetingMorning => 'Good morning!';

  @override
  String get greetingNoon => 'Good afternoon!';

  @override
  String get greetingAfternoon => 'Good afternoon!';

  @override
  String get greetingEvening => 'Good evening!';

  @override
  String greetingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes today. Nice!',
      one: '1 note today. Nice!',
    );
    return '$_temp0';
  }

  @override
  String get greetingEmpty => 'No notes yet today. Let\'s start!';

  @override
  String get journalPromptTitle => 'Today\'s question';

  @override
  String get journalPromptAction => 'Write an answer ›';

  @override
  String get journalPrompt1 => 'What small thing made you smile today?';

  @override
  String get journalPrompt2 => 'What are you most grateful for today?';

  @override
  String get journalPrompt3 => 'Which purchase today was most worth it?';

  @override
  String get journalPrompt4 => 'What would you like to do better tomorrow?';

  @override
  String get journalPrompt5 => 'Who made your day a little lighter?';

  @override
  String get updateAvailableTitle => 'A new version is here!';

  @override
  String updateAvailableBody(String version, String size) {
    return 'Nyawtat $version is available$size. Your data stays safe when updating.';
  }

  @override
  String get updateDownload => 'Download';

  @override
  String get updateWhatsNew => 'What\'s new?';

  @override
  String get updateLater => 'Later';

  @override
  String updateDownloading(String version) {
    return 'Downloading $version…';
  }

  @override
  String updateDownloadProgress(String done, String total) {
    return '$done / $total · you can keep using the app';
  }

  @override
  String get updateCancel => 'Cancel';

  @override
  String get updateReadyTitle => 'Ready to install!';

  @override
  String get updateReadyBody =>
      'The file has been verified. Installing takes just a few seconds.';

  @override
  String get updateInstallNow => 'Install now';

  @override
  String updateWhatsNewTitle(String version) {
    return 'What\'s new in $version';
  }

  @override
  String updateReleased(String date) {
    return 'Released $date';
  }

  @override
  String get updateInstallHint =>
      'Downloaded inside the app, then Android asks you to confirm the install. The first time, allow \"Install unknown apps\" for Nyawtat. Your data stays safe.';

  @override
  String get updateDownloadAndInstall => 'Download & install';

  @override
  String get updateOpenRelease => 'Open release page';

  @override
  String get updateRemindLater => 'Remind me later';

  @override
  String get updateErrorNetwork =>
      'Download failed. Check your internet and try again.';

  @override
  String get updateErrorChecksum =>
      'The update file doesn\'t match the official release, so it wasn\'t installed.';

  @override
  String get updateErrorPermission =>
      'Allow Nyawtat to install apps, then tap Install now again.';

  @override
  String get updateErrorSource =>
      'The update file isn\'t from an official Nyawtat release.';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String updateLastChecked(String when) {
    return 'Last checked: $when';
  }

  @override
  String get updateCheckNow => 'Check for updates';

  @override
  String get updateChecking => 'Nyaw is checking…';

  @override
  String updateVersionAvailable(String version) {
    return 'Version $version available';
  }

  @override
  String get updateUpToDate => 'You\'re on the latest version';

  @override
  String get updateCheckFailed =>
      'Couldn\'t check. Check your internet connection.';

  @override
  String get updateAuto => 'Check for updates automatically';

  @override
  String get updateAutoSub => 'Once a day when online';

  @override
  String get updatePrivacyNote =>
      'Nyawtat only reads the release list on GitHub. No personal data is sent.';

  @override
  String get aboutReleases => 'Version history';

  @override
  String get aboutTester => 'Become a tester';

  @override
  String get aboutTesterSub => 'Get new versions first';

  @override
  String get updateSnoozed => 'Okay! Nyaw will remind you tomorrow.';

  @override
  String get games => 'Games';

  @override
  String get gamesSub => 'Feeling worn out? Take a short break with Nyaw.';

  @override
  String get gameWheel => 'Spin wheel';

  @override
  String get gameRps => 'Rock paper scissors';

  @override
  String get gameWheelFood => 'What to eat?';

  @override
  String get gameWheelDrink => 'What to drink?';

  @override
  String get gameWheelYesNo => 'Yes / No';

  @override
  String get gameWheelActivity => 'What to do?';

  @override
  String get gameWheelFoodDefaults =>
      'Fried rice|Meatball soup|Chicken noodles|Soto|Smashed chicken|Gado-gado';

  @override
  String get gameWheelDrinkDefaults =>
      'Iced coffee|Iced tea|Avocado juice|Water';

  @override
  String get gameWheelYesNoDefaults => 'Yes|No';

  @override
  String get gameWheelActivityDefaults =>
      'Read a book|Evening walk|Watch a movie|Take a nap|Tidy up';

  @override
  String get gameSpin => 'Spin';

  @override
  String get gameSpinAgain => 'Spin again';

  @override
  String get gameReady => 'Ready?';

  @override
  String get gameTapSpin => 'Tap Spin';

  @override
  String get gameSpinning => 'Spinning…';

  @override
  String get gameWait => 'Hold on';

  @override
  String get gameNyawPicks => 'Nyaw picks';

  @override
  String get gameRecordExpense => 'Record expense';

  @override
  String get gameWheelItems => 'Wheel options';

  @override
  String gameWheelCount(int count, int max) {
    return '$count of max $max';
  }

  @override
  String get gameWheelAddHint => 'Add an option, e.g. Pizza';

  @override
  String gameRemoveOption(String name) {
    return 'Remove $name';
  }

  @override
  String get gameYou => 'You';

  @override
  String get gameRock => 'Rock';

  @override
  String get gameScissors => 'Scissors';

  @override
  String get gamePaper => 'Paper';

  @override
  String get gamePickHand => 'Pick your hand';

  @override
  String get gameCounting => 'Rock… paper… scissors!';

  @override
  String get gameWin => 'You win!';

  @override
  String get gameLose => 'Nyaw wins';

  @override
  String get gameTie => 'Tie, try again';

  @override
  String get gameTieLabel => 'Tie';

  @override
  String get gameScore => 'Score';

  @override
  String get gameResetScore => 'Reset';

  @override
  String get gameHubTitle => 'Time to unwind';

  @override
  String get gameHubHint =>
      'Feeling worn out? Play a little with Nyaw, then get back to it.';

  @override
  String get gameHubFootnote =>
      'Scores and records stay on your phone and are not synced.';

  @override
  String get gameRest => 'Take a break';

  @override
  String get gameRestAll => 'All games';

  @override
  String get gameShortWheel => 'Wheel';

  @override
  String get gameShortRps => 'RPS';

  @override
  String get gameShortMemory => 'Cards';

  @override
  String get gameShortPrompt => 'Ideas';

  @override
  String get gameWheelDesc => 'Can\'t decide what to eat? Let the wheel pick.';

  @override
  String get gameRpsDesc => 'Test your luck against Nyaw, scores are counted.';

  @override
  String get gameMemory => 'Memory cards';

  @override
  String get gameMemoryDesc => 'Match the pairs of Nyaw poses.';

  @override
  String get gameMemorySub => 'Match 6 pairs of Nyaw poses.';

  @override
  String gameMemoryRecord(int moves) {
    return 'Record $moves moves';
  }

  @override
  String get gameMoves => 'Moves';

  @override
  String get gamePairs => 'Pairs';

  @override
  String get gameBest => 'Record';

  @override
  String gameMemoryDone(int moves) {
    return 'Done in $moves moves';
  }

  @override
  String gameMemoryNewBest(int moves) {
    return 'New record: $moves moves!';
  }

  @override
  String gameMemoryBestLine(int moves) {
    return 'Your best is $moves moves.';
  }

  @override
  String get gamePlayAgain => 'Play again';

  @override
  String get gameReshuffle => 'Reshuffle';

  @override
  String gameCardClosed(int n) {
    return 'Face-down card $n';
  }

  @override
  String get gameCardOpen => 'Face-up card';

  @override
  String get gamePrompt => 'Shuffle a question';

  @override
  String get gamePromptDesc => 'Not sure what to write? Pick an idea.';

  @override
  String get gamePromptLabel => 'A question for you';

  @override
  String get gamePromptShuffle => 'Shuffle again';

  @override
  String get gamePromptWrite => 'Write the answer';

  @override
  String get gamePromptNote =>
      'The question becomes the title of a new journal entry, which you can change. Nothing is saved until you press Save.';

  @override
  String get gamePromptGratitude => 'Gratitude';

  @override
  String get gamePromptReflection => 'Reflection';

  @override
  String get gamePromptRelax => 'Relaxed';

  @override
  String get gamePromptDreams => 'Dreams';

  @override
  String get gamePromptGratitudeList =>
      'What small thing made you smile today?|Who would you like to thank today, and why?|What simple thing are you grateful for this week?|What was the best thing you ate today?|Whose presence made your day lighter?|What did your body let you do today that deserves thanks?|What unexpected thing turned out to be nice today?|Which object around you quietly makes your life easier?|What small kindness did you receive recently?|Which place makes you feel calm, and why are you thankful for it?|What went better than expected this morning?|Which teacher or friend\'s lesson still stays with you?|Which old memory still warms you up?|What problem once felt heavy but is behind you now?|What do you have now that used to be only a wish?|Which sound, smell, or view did you enjoy most today?|What opportunity came your way this week that you appreciate?|Which small comfort do you forget about, like clean water or a soft bed?|Who supports you quietly without being asked?|What did your last mistake teach you that you can be thankful for?|Which part of your routine do you actually like?|What was the last kind word you heard?|What made you feel like you had enough today?|If you wrote a thank-you letter to yourself, what would it say?';

  @override
  String get gamePromptReflectionList =>
      'What did you learn today?|If you could redo today, what would you do differently?|What drained your energy the most this week?|What is one thing you want to let go of?|When did you last feel completely like yourself?|Which decision are you putting off, and what holds you back?|What have you been avoiding lately, and why?|What do you do only out of habit, not because you want to?|What do you actually need right now, rather than just want?|Which word best describes this week, and why?|Which small habit affects your mood the most?|When did you feel most energized today?|Which conversation is still on your mind?|What do you regret, and what can you do about it?|What boundary do you need to set with others or yourself?|What are you proud of this month, however small?|Which task has felt most meaningful lately?|What are you worried about, and how likely is it really?|If you advised yourself a year ago, what would you say?|What is making you rush, and is it necessary?|Who do you need to call or apologize to?|What do you want to do less of starting tomorrow?|What pattern do you notice when your money runs out quickly?|What is one small step you can take this week?';

  @override
  String get gamePromptRelaxList =>
      'If today were a song, what would its title be?|Tell about one funny conversation today.|If tomorrow were a day off, where would you go?|What made you laugh most recently?|If today were a movie, what genre and title would it be?|Which snack would go best with today?|If you had one free hour with no interruptions, what would you do?|Which animal best matches your mood right now?|What color suits your day, and why?|Who would you have lunch with if you could pick anyone?|What quirky habit of yours do you secretly like?|Which song have you been replaying lately?|If you had a tiny but useful superpower, what would it be?|What is your favorite snack spot, and what do you usually order?|Tell about the most absurd thing you saw this week.|If Nyaw could spend the whole day with you, what would you two do?|What is the coziest thing to do when it rains?|If your life had a soundtrack, what would the opening song be?|What show or book do you want to finish?|If you opened a tiny shop, what would you sell?|If today had no budget but you could buy only one thing, what would it be?|Which childhood game do you miss most?|If you could sleep in tomorrow, what would you hope to dream?|What makes a weekend feel like a weekend to you?';

  @override
  String get gamePromptDreamsList =>
      'What is one thing you want to achieve this month?|If money were no issue, what would you buy first?|Who do you want to be in five years?|What good habit do you want to start?|Which skill do you want to master this year?|Which city or country do you want to visit, and why?|What does a perfect day look like to you, from waking up to sleeping?|What do you want to save for, and how long are you willing to wait?|If you could change one thing in your life right now, what would it be?|What kind of home do you dream of?|Which small project do you want to start before the year ends?|Who do you want to meet or reconnect with?|What do you want to teach others someday?|If failing were impossible, what would you try?|Which experience do you want to have once in your life?|What do you want to remember about this year?|Which book do you want to read or write?|Describe your ideal job in one sentence.|Which fear do you want to overcome?|Which bad habit do you want to replace with a better one?|What is your nearest financial goal?|What do you want to do with family or friends this year?|What would you like to tell yourself five years from now?|Which old dream do you still want to bring back to life?';

  @override
  String get updateCheckNotFound =>
      'No release found on GitHub yet. Try again later.';

  @override
  String get updateCheckRateLimited =>
      'Checked too often. Try again in a few minutes.';

  @override
  String get updateCheckServer => 'GitHub is having problems. Try again later.';

  @override
  String get calPrevMonth => 'Previous month';

  @override
  String get calNextMonth => 'Next month';

  @override
  String get calHint => 'Tap a date to see that day\'s transactions.';

  @override
  String get calShowAllDays => 'Show all days';

  @override
  String get calOut => 'Out';

  @override
  String get calIn => 'In';

  @override
  String get calDayEmpty => 'No transactions on this date.';

  @override
  String get calRecord => 'Record';

  @override
  String get calNoData => 'no data yet';

  @override
  String get remSection => 'REMINDERS FROM YOUR STORY';

  @override
  String get remNone =>
      'No date or time in your story yet. Mention a plan and Nyaw will offer a reminder here.';

  @override
  String get remDetected => 'Event detected';

  @override
  String get remWillRemind => 'Will remind you';

  @override
  String get remAllDay => 'All day';

  @override
  String get remTomorrow => 'Tomorrow';

  @override
  String remDaysLeft(int days) {
    return 'in $days days';
  }

  @override
  String get remAmbiguous => 'The time is unclear. Which one do you mean?';

  @override
  String remMismatch(String date, String actual, String said) {
    return '$date falls on $actual, not $said. Nyaw uses the date.';
  }

  @override
  String get remAccept => 'Remind me';

  @override
  String get remEdit => 'Edit';

  @override
  String get remDismiss => 'Ignore';

  @override
  String remActive(String lead) {
    return 'Reminder on · $lead';
  }

  @override
  String get remLeadAt => 'at the event';

  @override
  String get remLeadHour => '1 hour before';

  @override
  String get remLeadDay => '1 day before';

  @override
  String get remLeadMorning => 'that morning, 07:00';

  @override
  String get remLeadMorningShort => 'that morning';

  @override
  String get remPrivacy => 'Recognized on your own phone, no internet.';

  @override
  String get remEditTitle => 'Edit reminder';

  @override
  String get remEditSub => 'Fix it if Nyaw guessed wrong.';

  @override
  String get remFieldTitle => 'Event title';

  @override
  String get remFieldDate => 'Date';

  @override
  String get remFieldTime => 'Time';

  @override
  String get remFieldLead => 'Remind me';

  @override
  String get remSave => 'Save reminder';

  @override
  String get remDefaultTitle => 'Event';

  @override
  String get remPermTitle => 'Allow notifications?';

  @override
  String get remPermBody =>
      'So Nyawtat can remind you on time. Asked only once.';

  @override
  String get remPermHint =>
      'Without permission, events are still saved and shown on Today, but there are no notifications.';

  @override
  String get remPermLater => 'Not now';

  @override
  String get remPermAllow => 'Allow';

  @override
  String get remUpcoming => 'Upcoming events';

  @override
  String get remDenied =>
      'Notifications are not allowed, so events only appear in this list.';

  @override
  String get remAllowButton => 'Allow notifications';

  @override
  String remLeadLine(String lead) {
    return 'Reminds you $lead';
  }

  @override
  String remFrom(String date) {
    return 'From the entry on $date';
  }

  @override
  String get remDelete => 'Delete reminder';

  @override
  String get remClose => 'Close';

  @override
  String get remNotifHour => 'In 1 hour';

  @override
  String get remNotifNow => 'Now';

  @override
  String remCreated(int count) {
    return '$count reminders created';
  }
}
