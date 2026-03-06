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

  @HiveField(4)
  List<int> tabOrder = [0, 1, 2, 3, 4];

  UserSettings._privateConstructor();

  static final UserSettings _instance = UserSettings._privateConstructor();

  factory UserSettings() => _instance;

  UserSettings.initialize(UserSettings userSettings) {
    _instance.language = userSettings.language;
    _instance.showMega = userSettings.showMega;
    _instance.showBattle = userSettings.showBattle;
    _instance.capturedFeature = userSettings.capturedFeature;
    final stored = userSettings.tabOrder;
    // Migration: reset if old 7-tab order or invalid
    final validOrder = stored.length == 5 &&
        stored.toSet().length == 5 &&
        stored.every((id) => id >= 0 && id < 5);
    _instance.tabOrder = validOrder ? List<int>.from(stored) : [0, 1, 2, 3, 4];
    // Persist migration if needed
    if (!validOrder && userSettings.isInBox) {
      userSettings.tabOrder = List<int>.from(_instance.tabOrder);
      userSettings.save();
    }
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

  void setTabOrder(List<int> order) {
    tabOrder = order;
    notifyListeners();
    save();
  }
}
