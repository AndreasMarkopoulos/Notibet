import 'package:shared_preferences/shared_preferences.dart';

class PicksPreferences {
  static late SharedPreferences _preferences;

  static const _keyPicks = 'picks';

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future setPicks(List<String> picks) async =>
      await _preferences.setStringList(_keyPicks, picks);

  static List<String> getPicks() =>
      _preferences.getStringList(_keyPicks);
}