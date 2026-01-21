import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ui/snackbar.dart';

class MediaPermissions {
  const MediaPermissions._();

  static Future<void> requestPhotoVideoAccess(BuildContext context) async {
    if (kIsWeb) {
      if (context.mounted) {
        AppSnack.show(
          context,
          'Photo and video access is managed by your browser settings.',
          error: false,
        );
      }
      return;
    }

    final permissions = <Permission>[
      Permission.photos,
      Permission.videos,
      if (defaultTargetPlatform == TargetPlatform.android) Permission.storage,
    ];

    final statuses = await permissions.request();
    final denied = statuses.entries
        .where((entry) => !entry.value.isGranted)
        .map((entry) => entry.key)
        .toList();

    if (denied.isEmpty) {
      if (context.mounted) {
        AppSnack.show(context, 'Photo and video access granted.', error: false);
      }
      return;
    }

    final permanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);
    if (context.mounted) {
      AppSnack.show(
        context,
        permanentlyDenied
            ? 'Please enable photo and video access in Settings.'
            : 'Photo and video access is required to attach media.',
        error: true,
      );
    }

    if (permanentlyDenied) {
      await openAppSettings();
    }
  }
}
