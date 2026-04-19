class AppConstants {
  AppConstants._();

  static const String needsCollection = 'needs';
  static const String volunteersCollection = 'volunteers';
  static const String ngosCollection = 'ngos';

  static const String statusRaw = 'RAW';
  static const String statusScored = 'SCORED';
  static const String statusAssigned = 'ASSIGNED';
  static const String statusInProgress = 'IN_PROGRESS';
  static const String statusCompleted = 'COMPLETED';

  static const String needFood = 'FOOD';
  static const String needMedical = 'MEDICAL';
  static const String needShelter = 'SHELTER';
  static const String needClothing = 'CLOTHING';
  static const String needOther = 'OTHER';

  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String nominatimUserAgent = 'SevakAI/1.0 (sevakai@gmail.com)';

  static const String cloudinaryBaseUrl = 'https://api.cloudinary.com/v1_1';

  static const double maxMatchingRadiusKm = 25.0;
  static const double expandedMatchingRadiusKm = 50.0;

  static const String workManagerLocationTaskName = 'sevakai_location_update';
  static const Duration locationUpdateInterval = Duration(minutes: 15);
  static const Duration staleLocationThreshold = Duration(hours: 2);

  static const int geminiMaxRetries = 3;
  static const Duration geminiBaseRetryDelay = Duration(seconds: 2);

  static const int imageMaxWidthPx = 1080;
  static const int imageTargetSizeKb = 150;
}
