import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 0)
class UserSettings extends HiveObject with ChangeNotifier {
  @HiveField(0)
  String language = 'fr';

  @HiveField(1)
  bool showMega = false;

  @HiveField(2)
  bool showBattle = false;

  @HiveField(3)
  bool capturedFeature = false;

  UserSettings._privateConstructor();

  static final UserSettings _instance = UserSettings._privateConstructor();

  factory UserSettings() => _instance;

  UserSettings.initialize(UserSettings userSettings) {
    language = userSettings.language;
    showMega = userSettings.showMega;
    showBattle = userSettings.showBattle;
    capturedFeature = userSettings.capturedFeature;
  }

  void changeLanguage(String newLanguage) {
    language = newLanguage;
    notifyListeners();
    save();
  }

  void setShowMega(bool value) {
    showMega = value;
    notifyListeners();
    save();
  }

  void setShowBattle(bool value) {
    showBattle = value;
    notifyListeners();
    save();
  }

  void setCapturedFeature(bool value) {
    capturedFeature = value;
    notifyListeners();
    save();
  }
}
