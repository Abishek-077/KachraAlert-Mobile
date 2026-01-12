import 'package:hive/hive.dart';

part 'settings_hive_model.g.dart';

@HiveType(typeId: 10)
class SettingsHiveModel extends HiveObject {
  @HiveField(0)
  final bool isDarkMode;

  @HiveField(1)
  final bool isOnboarded;

  SettingsHiveModel({required this.isDarkMode, required this.isOnboarded});

  SettingsHiveModel copyWith({bool? isDarkMode, bool? isOnboarded}) {
    return SettingsHiveModel(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }

  factory SettingsHiveModel.defaultValue() {
    return SettingsHiveModel(isDarkMode: false, isOnboarded: false);
  }
}
