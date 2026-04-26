/// Centralised constants for the SevakAI platform.
/// Every magic string, threshold, and collection name lives here.
class AppConstants {
  AppConstants._();

  static const String needsCollection = 'needs';
  static const String volunteersCollection = 'volunteers';
  static const String ngosCollection = 'ngos';
  static const String ngoInvitesCollection = 'ngoInvites';
  static const String joinRequestsCollection = 'joinRequests';
  static const String partnershipsCollection = 'partnerships';
  static const String crossNgoTasksCollection = 'crossNgoTasks';
  static const String communityReportsCollection = 'communityReports';
  static const String platformConfigCollection = 'platformConfig';
  static const String impactStoriesCollection = 'impactStories'; // Volunteer task completion stories

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

  /// Maps volunteer skill keywords to need types they can serve.
  /// Used by the matching engine to compute a skill relevance score.
  static const Map<String, List<String>> skillToNeedTypes = {
    // MEDICAL skills
    'first aid': [needMedical],
    'nursing': [needMedical],
    'paramedic': [needMedical],
    'doctor': [needMedical],
    'healthcare': [needMedical],
    'cpr': [needMedical],
    'pharmacy': [needMedical],
    // FOOD skills
    'cooking': [needFood],
    'nutrition': [needFood],
    'food distribution': [needFood],
    'catering': [needFood],
    // SHELTER skills
    'construction': [needShelter],
    'carpentry': [needShelter],
    'plumbing': [needShelter],
    'electrician': [needShelter],
    'architecture': [needShelter],
    // CLOTHING skills
    'tailoring': [needClothing],
    'textiles': [needClothing],
    // MULTI-PURPOSE skills
    'driving': [needFood, needMedical, needShelter, needClothing],
    'logistics': [needFood, needMedical, needShelter, needClothing],
    'translation': [needFood, needMedical, needShelter, needClothing],
    'counseling': [needMedical, needShelter],
    'teaching': [needOther],
    'social work': [needMedical, needShelter, needOther],
  };

  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  static const String cloudinaryBaseUrl = 'https://api.cloudinary.com/v1_1';

  static const double maxMatchingRadiusKm = 25.0;
  static const double expandedMatchingRadiusKm = 50.0;
  static const int defaultMaxConcurrentTasks = 3;

  static const String workManagerLocationTaskName = 'sevakai_location_update';
  static const Duration locationUpdateInterval = Duration(minutes: 15);
  static const Duration staleLocationThreshold = Duration(hours: 2);

  static const int aiMaxRetries = 3;
  static const Duration aiBaseRetryDelay = Duration(seconds: 2);
  static const Duration aiRequestTimeout = Duration(seconds: 45);

  static const int imageMaxWidthPx = 1080;
  static const int imageTargetSizeKb = 150;

  // Lowered from 80 → 50 so medium-urgency needs also get auto-matched.
  static const int autoAssignUrgencyThreshold = 50;
}
