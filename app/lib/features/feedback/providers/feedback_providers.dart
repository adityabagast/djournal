import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feedback_service.dart';

final feedbackServiceProvider = Provider((ref) => FeedbackService());
