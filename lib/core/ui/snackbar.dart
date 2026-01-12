import 'package:flutter/material.dart';

class AppSnack {
  static void show(BuildContext context, String message, {bool error = true}) {
    final snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(14),
      showCloseIcon: true,
      duration: const Duration(seconds: 3),
      backgroundColor: error
          ? const Color(0xFFB42318)
          : const Color(0xFF027A48),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
