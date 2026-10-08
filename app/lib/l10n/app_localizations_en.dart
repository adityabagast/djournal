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
  String get deleteTxConfirm => 'Delete this transaction?';

  @override
  String get quickAdd => 'Quick add';

  @override
  String get quickAddTx => 'Add transaction';

  @override
  String get quickAddTxSub => 'Expense or income';

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
}
