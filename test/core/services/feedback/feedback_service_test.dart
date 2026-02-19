import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/core/services/feedback/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final methodCalls = <MethodCall>[];

  setUp(() {
    methodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      methodCalls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('does not dispatch haptic calls when disabled', () async {
    const service = FeedbackService(enabled: false);

    await service.selection();
    await service.lightImpact();
    await service.mediumImpact();
    await service.heavyImpact();
    await service.success();
    await service.error();

    expect(methodCalls, isEmpty);
  });

  test('dispatches platform haptic call when enabled', () async {
    const service = FeedbackService(enabled: true);

    await service.selection();

    expect(methodCalls, isNotEmpty);
    expect(methodCalls.first.method, 'HapticFeedback.vibrate');
  });
}
