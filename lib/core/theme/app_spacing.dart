import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double screenPadding = 24;
  static const double sectionSpacing = 16;
  static const double componentPadding = 12;
  static const double labelSpacing = 8;
  static const double itemSpacing = 12;

  static const EdgeInsets screenInsets = EdgeInsets.all(screenPadding);
  static const EdgeInsets screenInsetsBottom =
      EdgeInsets.fromLTRB(screenPadding, screenPadding, screenPadding, 120);
  static const EdgeInsets bottomBarInsets =
      EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, 16);
}
