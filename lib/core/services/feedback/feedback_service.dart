import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../extensions/async_value_extensions.dart';
import '../../../features/settings/presentation/providers/settings_providers.dart';

class FeedbackService {
  const FeedbackService({required this.enabled});

  final bool enabled;

  Future<void> selection() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  Future<void> lightImpact() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> mediumImpact() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavyImpact() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> success() => mediumImpact();

  Future<void> error() => heavyImpact();
}

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  return FeedbackService(enabled: settings?.hapticsEnabled ?? true);
});
