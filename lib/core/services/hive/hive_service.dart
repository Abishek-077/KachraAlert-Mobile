// core/services/hive/hive_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart'; // ← IMPORTANT: Use hive_flutter
import 'package:kachra_alert/core/constants/hive_table_constant.dart';
import 'package:kachra_alert/features/alert/data/models/alert_hive_model.dart';
import 'package:kachra_alert/features/auth/data/models/user_hive_model.dart';
import 'package:kachra_alert/features/collection/data/models/collection_schedule_hive_model.dart';
import 'package:kachra_alert/features/comment/data/models/comment_hive_model.dart';
import 'package:kachra_alert/features/reward/data/models/reward_hive_model.dart';
import 'package:kachra_alert/features/waste_bin/data/models/waste_bin_hive_model.dart';
import 'package:kachra_alert/features/waste_category/data/models/waste_category_hive_model.dart';
import 'package:kachra_alert/features/waste_report/data/models/waste_report_hive_model.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  static const String _dbName =
      HiveTableConstant.dbName; // e.g., 'kachra_alert_db'

  /// Initialize Hive properly for Flutter
  Future<void> init() async {
    try {
      // Correct way for Flutter mobile apps
      await Hive.initFlutter(_dbName); // This creates a subfolder safely

      // Alternative (less recommended): Use custom path
      // final directory = await getApplicationDocumentsDirectory();
      // Hive.init('${directory.path}/hive');

      _registerAdapters();
      await _openBoxes();
      await _insertInitialDataIfNeeded();
    } catch (e) {
      // In production, log this properly (e.g., Crashlytics)
      print('Hive initialization failed: $e');
      rethrow;
    }
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveTableConstant.userTypeId)) {
      Hive.registerAdapter(UserHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.wasteReportTypeId)) {
      Hive.registerAdapter(WasteReportHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.wasteBinTypeId)) {
      Hive.registerAdapter(WasteBinHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.collectionScheduleTypeId)) {
      Hive.registerAdapter(CollectionScheduleHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.alertTypeId)) {
      Hive.registerAdapter(AlertHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.wasteCategoryTypeId)) {
      Hive.registerAdapter(WasteCategoryHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.commentTypeId)) {
      Hive.registerAdapter(CommentHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.rewardTypeId)) {
      Hive.registerAdapter(RewardHiveModelAdapter());
    }
  }

  Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox<UserHiveModel>(HiveTableConstant.userTable),
      Hive.openBox<WasteReportHiveModel>(HiveTableConstant.wasteReportTable),
      Hive.openBox<WasteBinHiveModel>(HiveTableConstant.wasteBinTable),
      Hive.openBox<CollectionScheduleHiveModel>(
        HiveTableConstant.collectionScheduleTable,
      ),
      Hive.openBox<AlertHiveModel>(HiveTableConstant.alertTable),
      Hive.openBox<WasteCategoryHiveModel>(
        HiveTableConstant.wasteCategoryTable,
      ),
      Hive.openBox<CommentHiveModel>(HiveTableConstant.commentTable),
      Hive.openBox<RewardHiveModel>(HiveTableConstant.rewardTable),
    ]);
  }

  Future<void> _insertInitialDataIfNeeded() async {
    await _insertWasteCategoriesIfEmpty();
    await _insertWasteBinsIfEmpty();
    await _insertCollectionSchedulesIfEmpty();
  }

  // ==================== Initial Dummy Data ====================

  Future<void> _insertWasteCategoriesIfEmpty() async {
    final box = Hive.box<WasteCategoryHiveModel>(
      HiveTableConstant.wasteCategoryTable,
    );
    if (box.isNotEmpty) return;

    final categories = [
      WasteCategoryHiveModel(
        id: 'cat1',
        name: 'General Waste',
        description: 'Household trash',
      ),
      WasteCategoryHiveModel(
        id: 'cat2',
        name: 'Recyclable',
        description: 'Paper, plastic, glass, metal',
      ),
      WasteCategoryHiveModel(
        id: 'cat3',
        name: 'Organic',
        description: 'Food scraps, yard waste',
      ),
      WasteCategoryHiveModel(
        id: 'cat4',
        name: 'Hazardous',
        description: 'Batteries, chemicals, e-waste',
      ),
      WasteCategoryHiveModel(
        id: 'cat5',
        name: 'Medical',
        description: 'Syringes, expired medicines',
      ),
    ];

    for (final cat in categories) {
      await box.put(cat.id, cat);
    }
  }

  Future<void> _insertWasteBinsIfEmpty() async {
    final box = Hive.box<WasteBinHiveModel>(HiveTableConstant.wasteBinTable);
    if (box.isNotEmpty) return;

    final bins = [
      WasteBinHiveModel(
        binId: 'BIN001',
        locationName: 'Sector 17 Market',
        latitude: 30.7333,
        longitude: 76.7794,
        fillLevel: 65.0,
        categoryId: 'cat2', // Recyclable
        status: 'active',
      ),
      WasteBinHiveModel(
        binId: 'BIN002',
        locationName: 'Rose Garden',
        latitude: 30.7461,
        longitude: 76.7803,
        fillLevel: 90.0,
        categoryId: 'cat1', // General Waste
        status: 'overflow',
      ),
    ];

    for (final bin in bins) {
      await box.put(bin.binId, bin);
    }
  }

  Future<void> _insertCollectionSchedulesIfEmpty() async {
    final box = Hive.box<CollectionScheduleHiveModel>(
      HiveTableConstant.collectionScheduleTable,
    );
    if (box.isNotEmpty) return;

    final schedules = [
      CollectionScheduleHiveModel(
        routeId: 'ROUTE001',
        area: 'Sector 17-22',
        dayOfWeek: 'Monday, Thursday',
        time: '7:00 AM - 9:00 AM',
        wasteTypes: ['General Waste', 'Recyclable'],
        days: '',
      ),
      CollectionScheduleHiveModel(
        routeId: 'ROUTE002',
        area: 'Sector 35-44',
        dayOfWeek: 'Tuesday, Friday',
        time: '6:30 AM - 8:30 AM',
        wasteTypes: ['Organic', 'General Waste'],
        days: '',
      ),
    ];

    for (final schedule in schedules) {
      await box.put(schedule.routeId, schedule);
    }
  }

  // ==================== Public Box Getters ====================

  Box<UserHiveModel> get userBox =>
      Hive.box<UserHiveModel>(HiveTableConstant.userTable);
  Box<WasteReportHiveModel> get reportBox =>
      Hive.box<WasteReportHiveModel>(HiveTableConstant.wasteReportTable);
  Box<WasteBinHiveModel> get binBox =>
      Hive.box<WasteBinHiveModel>(HiveTableConstant.wasteBinTable);
  Box<CollectionScheduleHiveModel> get scheduleBox =>
      Hive.box<CollectionScheduleHiveModel>(
        HiveTableConstant.collectionScheduleTable,
      );
  Box<AlertHiveModel> get alertBox =>
      Hive.box<AlertHiveModel>(HiveTableConstant.alertTable);
  Box<WasteCategoryHiveModel> get categoryBox =>
      Hive.box<WasteCategoryHiveModel>(HiveTableConstant.wasteCategoryTable);
  Box<CommentHiveModel> get commentBox =>
      Hive.box<CommentHiveModel>(HiveTableConstant.commentTable);
  Box<RewardHiveModel> get rewardBox =>
      Hive.box<RewardHiveModel>(HiveTableConstant.rewardTable);

  // ==================== Utility Methods ====================

  /// Clears all data — useful for testing/logout
  Future<void> clearAllData() async {
    await Future.wait([
      userBox.clear(),
      reportBox.clear(),
      binBox.clear(),
      scheduleBox.clear(),
      alertBox.clear(),
      categoryBox.clear(),
      commentBox.clear(),
      rewardBox.clear(),
    ]);
  }

  Future<void> close() async {
    await Hive.close();
  }

  Future<void> clearAllBoxes() async {}
}
