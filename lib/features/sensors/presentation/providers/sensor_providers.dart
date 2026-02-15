import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorSnapshot {
  final double x;
  final double y;
  final double z;

  const SensorSnapshot({required this.x, required this.y, required this.z});

  double get magnitude => math.sqrt((x * x) + (y * y) + (z * z));

  String get formatted =>
      'x:${x.toStringAsFixed(1)} y:${y.toStringAsFixed(1)} z:${z.toStringAsFixed(1)}';
}

final accelerometerProvider = StreamProvider.autoDispose<SensorSnapshot>((ref) {
  return accelerometerEvents.map(
    (event) => SensorSnapshot(x: event.x, y: event.y, z: event.z),
  );
});

final gyroscopeProvider = StreamProvider.autoDispose<SensorSnapshot>((ref) {
  return gyroscopeEvents.map(
    (event) => SensorSnapshot(x: event.x, y: event.y, z: event.z),
  );
});

final magnetometerProvider = StreamProvider.autoDispose<SensorSnapshot>((ref) {
  return magnetometerEvents.map(
    (event) => SensorSnapshot(x: event.x, y: event.y, z: event.z),
  );
});

class SensorInsight {
  final String title;
  final String detail;
  final bool isAlert;

  const SensorInsight({
    required this.title,
    required this.detail,
    required this.isAlert,
  });
}

final sensorInsightsProvider = Provider.autoDispose<List<SensorInsight>>((ref) {
  final accel = ref.watch(accelerometerProvider).valueOrNull;
  final gyro = ref.watch(gyroscopeProvider).valueOrNull;
  final magnet = ref.watch(magnetometerProvider).valueOrNull;

  if (accel == null || gyro == null || magnet == null) {
    return const <SensorInsight>[];
  }

  final accelMagnitude = accel.magnitude;
  final gyroMagnitude = gyro.magnitude;
  final magnetMagnitude = magnet.magnitude;

  final isShakeLikely = accelMagnitude > 16;
  final isTiltLikely = gyroMagnitude > 2.5;
  final isMagneticNoiseLikely = magnetMagnitude > 120;

  return [
    SensorInsight(
      title: 'Motion detector',
      detail: isShakeLikely
          ? 'Strong movement detected near your phone.'
          : 'Movement is stable right now.',
      isAlert: isShakeLikely,
    ),
    SensorInsight(
      title: 'Tilt detector',
      detail: isTiltLikely
          ? 'Phone is rotating quickly.'
          : 'Tilt and rotation are normal.',
      isAlert: isTiltLikely,
    ),
    SensorInsight(
      title: 'Magnetic detector',
      detail: isMagneticNoiseLikely
          ? 'High magnetic disturbance nearby.'
          : 'Magnetic field is in the usual range.',
      isAlert: isMagneticNoiseLikely,
    ),
  ];
});
