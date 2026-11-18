import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../data/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider(
  (ref) => WishlistRepository(ref.watch(databaseProvider)),
);

final wishlistsProvider = StreamProvider<List<Wishlist>>(
  (ref) => ref.watch(wishlistRepositoryProvider).watchWishlists(),
);
