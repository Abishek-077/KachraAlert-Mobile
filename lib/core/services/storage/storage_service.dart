// core/services/storage_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:kachra_alert/core/services/hive/hive_service.dart';
import 'package:kachra_alert/features/alert/data/models/alert_hive_model.dart';
import 'package:kachra_alert/features/auth/data/models/user_hive_model.dart';
import 'package:kachra_alert/features/collection/data/models/collection_schedule_hive_model.dart';
import 'package:kachra_alert/features/comment/data/models/comment_hive_model.dart';
import 'package:kachra_alert/features/reward/data/models/reward_hive_model.dart';
import 'package:kachra_alert/features/waste_bin/data/models/waste_bin_hive_model.dart';
import 'package:kachra_alert/features/waste_category/data/models/waste_category_hive_model.dart';
import 'package:kachra_alert/features/waste_report/data/models/waste_report_hive_model.dart';

import 'user_session_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final hive = ref.read(hiveServiceProvider);
  final session = ref.read(userSessionServiceProvider);
  return StorageService(hiveService: hive, sessionService: session);
});

class StorageService {
  final HiveService _hiveService;
  final UserSessionService _sessionService;

  StorageService({
    required HiveService hiveService,
    required UserSessionService sessionService,
  }) : _hiveService = hiveService,
       _sessionService = sessionService;

  // Direct box access
  Box<UserHiveModel> get userBox => _hiveService.userBox;
  Box<WasteReportHiveModel> get reportBox => _hiveService.reportBox;
  Box<WasteBinHiveModel> get binBox => _hiveService.binBox;
  Box<CollectionScheduleHiveModel> get scheduleBox => _hiveService.scheduleBox;
  Box<AlertHiveModel> get alertBox => _hiveService.alertBox;
  Box<WasteCategoryHiveModel> get categoryBox => _hiveService.categoryBox;
  Box<CommentHiveModel> get commentBox => _hiveService.commentBox;
  Box<RewardHiveModel> get rewardBox => _hiveService.rewardBox;

  // Current User Aware Helpers
  UserHiveModel? get currentUser {
    final userId = _sessionService.getUserId();
    return userId != null ? userBox.get(userId) : null;
  }

  List<WasteReportHiveModel> get myReports {
    final userId = _sessionService.getUserId();
    if (userId == null) return [];
    return reportBox.values.where((r) => r.reportedBy == userId).toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
  }

  List<AlertHiveModel> get unreadAlerts {
    final userId = _sessionService.getUserId();
    if (userId == null) return [];
    return alertBox.values
        .where((a) => a.userId == userId && !a.isRead)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<WasteBinHiveModel> get overflowingBins {
    return binBox.values.where((b) => b.fillLevel >= 85.0).toList();
  }

  List<WasteCategoryHiveModel> get allCategories => categoryBox.values.toList();

  List<CollectionScheduleHiveModel> get allSchedules =>
      scheduleBox.values.toList();

  // Reward System
  Future<void> awardPoints(int points, String reason) async {
    final userId = _sessionService.getUserId();
    if (userId == null) return;

    final reward = rewardBox.get(userId) ?? RewardHiveModel(userId: userId)
      ..totalPoints = 0;
    reward.totalPoints += points;
    reward.history.add(
      RewardHistoryEntry(points: points, reason: reason, date: DateTime.now()),
    );
    await rewardBox.put(userId, reward);
  }

  RewardHiveModel? get myRewards {
    final userId = _sessionService.getUserId();
    return userId != null ? rewardBox.get(userId) : null;
  }

  // Full Reset
  Future<void> clearAllData() async {
    await _sessionService.logout();
    await _hiveService.clearAllBoxes();
  }

  Future<void> reinitialize() async {
    await _hiveService.init();
  }
}
