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
  String get googleSignIn => 'Continue with Google';

  @override
  String get googleSignInPrompt =>
      'Sign in with Google to automatically backup to Google Drive.';

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
}
