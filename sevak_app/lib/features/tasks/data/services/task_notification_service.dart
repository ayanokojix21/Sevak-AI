import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service that listens to Firestore in real-time for newly ASSIGNED tasks
/// and fires a local notification to the volunteer.
class TaskNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Must be called once at app startup (in main.dart).
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _initialized = true;
    debugPrint('[TaskNotificationService] Initialized');
  }

  /// Start a Firestore listener for the volunteer. Call this after login.
  /// Returns a cancel function to tear down the listener on logout.
  static Stream<void> startTaskListener(String volunteerUid) {
    return FirebaseFirestore.instance
        .collection('needs')
        .where('assignedTo', isEqualTo: volunteerUid)
        .where('status', isEqualTo: 'ASSIGNED')
        .snapshots()
        .asyncMap((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() ?? {};
          final needType = data['needType'] as String? ?? 'Task';
          final location = data['location'] as String? ?? 'Unknown location';

          await _notificationsPlugin.show(
            change.doc.id.hashCode,
            'New Task Assigned \u2014 $needType',
            location,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'sevak_tasks',
                'Task Assignments',
                channelDescription: 'Notifications for new volunteer task assignments',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
          debugPrint('[TaskNotificationService] Fired notification for task ${change.doc.id}');
        }
      }
    });
  }
}
