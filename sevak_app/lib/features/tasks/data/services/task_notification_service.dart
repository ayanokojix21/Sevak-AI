import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../core/constants/app_constants.dart';

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

  /// Explicitly request permissions (Android 13+).
  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Start a Firestore listener for the volunteer. Call this after login.
  /// Returns a cancel function to tear down the listener on logout.
  static void startTaskListener(String volunteerUid) {
    FirebaseFirestore.instance
        .collection(AppConstants.needsCollection)
        .where('assignedVolunteerIds', arrayContains: volunteerUid)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() ?? {};
          final status = data['status'] as String? ?? '';
          
          if (status == 'ASSIGNED') {
            final needType = data['needType'] as String? ?? 'Task';
            final location = data['location'] as String? ?? 'Unknown location';

            if (kIsWeb) return;
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
      }
    });
  }

  /// Start a listener for NGO Coordinators to track assignments.
  static void startCoordinatorListener(String ngoId) {
    FirebaseFirestore.instance
        .collection(AppConstants.needsCollection)
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        // Detect when a task enters ASSIGNED status
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data() ?? {};
          final status = data['status'] as String? ?? '';
          
          if (status == 'ASSIGNED') {
            final needType = data['needType'] as String? ?? 'Task';
            
            if (kIsWeb) return;
            await _notificationsPlugin.show(
              change.doc.id.hashCode + 1, // Offset ID to avoid collision
              'Volunteer Assigned \u2014 $needType',
              'A volunteer has been assigned to an emergency in your NGO.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'sevak_coordinator',
                  'NGO Coordination',
                  channelDescription: 'Notifications for NGO coordinators',
                  importance: Importance.high,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                ),
              ),
            );
            debugPrint('[TaskNotificationService] Fired coordinator notification for ${change.doc.id}');
          }
        }
      }
    });
  }
}
