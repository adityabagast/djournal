import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import 'database_providers.dart';

final wishlistsProvider = StreamProvider<List<Wishlist>>(
  (ref) => ref.watch(wishlistRepositoryProvider).watchWishlists(),
);
