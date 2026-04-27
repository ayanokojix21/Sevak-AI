import 'package:shared_preferences/shared_preferences.dart';

/// Persists the currently-logged-in volunteer's UID so that
/// the WorkManager background isolate (which cannot access
/// Firebase Auth streams) can still perform location updates.
class PrefsService {
  static const _kVolunteerUid = 'volunteer_uid';

  /// Call after every successful sign-in.
  static Future<void> saveVolunteerUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVolunteerUid, uid);
  }

  /// Call on sign-out so the background task stops updating.
  static Future<void> clearVolunteerUid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kVolunteerUid);
  }

  /// Returns the saved UID, or null if the user is not logged in.
  static Future<String?> getVolunteerUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kVolunteerUid);
  }
}
