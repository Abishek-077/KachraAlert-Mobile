import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compat helper for older Riverpod APIs that exposed `valueOrNull`.
extension AsyncValueCompatX<T> on AsyncValue<T> {
  T? get valueOrNull => asData?.value;
}
