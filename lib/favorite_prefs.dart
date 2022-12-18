import 'package:shared_preferences/shared_preferences.dart';

class FavoritePreferences {
  static late SharedPreferences _preferences;

  static const _keyFavorites = 'favorites';
  static const _keyPicks = 'picks';

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();
  
  static Future setFavorites(List<String> favorites) async =>
      await _preferences.setStringList(_keyFavorites, favorites);

  static List<String> getFavorites() =>
      _preferences.getStringList(_keyFavorites);

  static Future setPicks(List<String> picks) async =>
      await _preferences.setStringList(_keyPicks, picks);

  static List<String> getPicks() =>
      _preferences.getStringList(_keyPicks);
}