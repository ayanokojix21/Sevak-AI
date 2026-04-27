import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/constants/super_admin_config.dart';
import 'core/services/prefs_service.dart';
import 'features/location/data/location_service.dart';
import 'features/tasks/data/services/task_notification_service.dart';

/// Top-level WorkManager callback — runs in an isolated Dart isolate.
/// Firebase Auth is NOT available here; we read the UID from SharedPreferences.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'sevakai_location_update') {
      // Firebase must be initialised explicitly in the background isolate.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final uid = await PrefsService.getVolunteerUid();
      if (uid != null && uid.isNotEmpty) {
        await LocationService().updateVolunteerLocation(uid, force: true);
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  await Workmanager().initialize(callbackDispatcher);

  // 1-hour periodic background location update.
  // `existingWorkPolicy: keep` prevents re-registering if already scheduled.
  await Workmanager().registerPeriodicTask(
    '1',
    'sevakai_location_update',
    frequency: const Duration(hours: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  // Initialise local notifications (Phase 4F)
  await TaskNotificationService.initialize();

  // Load Super Admin email list from Firestore (seeds defaults on first run)
  await SuperAdminConfig().initialize();

  runApp(
    const ProviderScope(
      child: SevakApp(),
    ),
  );
}
