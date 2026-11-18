import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../data/bill_repository.dart';

final billRepositoryProvider = Provider(
  (ref) => BillRepository(ref.watch(databaseProvider)),
);

final billsProvider = StreamProvider<List<Bill>>(
  (ref) => ref.watch(billRepositoryProvider).watchBills(),
);

final unpaidBillsProvider = StreamProvider<List<Bill>>(
  (ref) => ref.watch(billRepositoryProvider).watchUnpaidBills(),
);
