import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

class StorageService {
  static const String _profileKey = 'block_forge_profile_v1';

  Future<PlayerProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    PlayerProfile profile;
    if (raw == null || raw.isEmpty) {
      profile = PlayerProfile();
    } else {
      try {
        profile = PlayerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        profile = PlayerProfile();
      }
    }
    _refreshDailyQuestsIfNeeded(profile);
    return profile;
  }

  Future<void> saveProfile(PlayerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  void _refreshDailyQuestsIfNeeded(PlayerProfile profile) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    if (profile.lastQuestDate != todayStr) {
      profile.lastQuestDate = todayStr;
      profile.dailyQuests = PlayerProfile.defaultQuests();
    }
  }
}
