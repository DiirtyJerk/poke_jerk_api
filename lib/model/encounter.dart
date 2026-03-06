import 'package:poke_jerk_api/utils/string_utils.dart';

class LocationEncounter {
  final int locationId;
  final String locationIdentifier;
  final Map<int, String> locationNames;
  final Map<int, String> versionNames;
  final Map<int, String> methodNames;
  final String versionIdentifier;
  final int versionId;
  final int slotId;
  final int minLevel;
  final int maxLevel;
  final int chance;

  LocationEncounter({
    required this.locationId,
    required this.locationIdentifier,
    required this.locationNames,
    required this.versionNames,
    required this.methodNames,
    required this.versionIdentifier,
    required this.versionId,
    required this.slotId,
    required this.minLevel,
    required this.maxLevel,
    required this.chance,
  });

  factory LocationEncounter.fromJson(Map<String, dynamic> json) {
    final locationNames = <int, String>{};
    final area = json['pokemon_v2_locationarea'] as Map<String, dynamic>?;
    final location = area?['pokemon_v2_location'] as Map<String, dynamic>?;
    if (location != null) {
      for (final n in (location['pokemon_v2_locationnames'] as List? ?? [])) {
        locationNames[n['language_id'] as int] = n['name'] as String;
      }
    }

    final versionNames = <int, String>{};
    final version = json['pokemon_v2_version'] as Map<String, dynamic>?;
    if (version != null) {
      for (final n in (version['pokemon_v2_versionnames'] as List? ?? [])) {
        versionNames[n['language_id'] as int] = n['name'] as String;
      }
    }

    final slot = json['pokemon_v2_encounterslot'] as Map<String, dynamic>?;
    final methodNames = <int, String>{};
    final method = slot?['pokemon_v2_encountermethod'] as Map<String, dynamic>?;
    if (method != null) {
      for (final n in (method['pokemon_v2_encountermethodnames'] as List? ?? [])) {
        methodNames[n['language_id'] as int] = n['name'] as String;
      }
    }

    return LocationEncounter(
      locationId: location?['id'] as int? ?? 0,
      locationIdentifier: location?['name'] as String? ?? '',
      locationNames: locationNames,
      versionNames: versionNames,
      methodNames: methodNames,
      versionIdentifier: version?['name'] as String? ?? '',
      versionId: version?['id'] as int? ?? 0,
      slotId: json['encounter_slot_id'] as int? ?? 0,
      minLevel: json['min_level'] as int? ?? 0,
      maxLevel: json['max_level'] as int? ?? 0,
      chance: slot?['rarity'] as int? ?? 0,
    );
  }

  String getLocationName(String language) => localizedName(locationNames, language);
  String getVersionName(String language) => localizedName(versionNames, language);
  String getMethodName(String language) => localizedName(methodNames, language);
}
