import 'package:flutter/material.dart';

class CollectionSchedule {
  final String id;
  final String type;
  final String day;
  final String time;
  final String status;
  final IconData icon;
  final Gradient gradient;

  CollectionSchedule({
    required this.id,
    required this.type,
    required this.day,
    required this.time,
    required this.status,
    required this.icon,
    required this.gradient,
  });
}
